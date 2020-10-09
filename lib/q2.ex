defmodule Q2 do
  @moduledoc """
  Sync all blockheaders from bitcoind node via JSON rpc.

  How to use:

  Set proper "user", "password", "endpint" of your bitcoind node.

  run `Q2.start()` or `Q2.start("any-block-hash")`

  The list of all blocks that mined after last block more then 2 hours
  will be record in `log` file.
  """

  @user "example"
  @password "example"
  @endpoint "https://you-bitcoin-node.com"
  @twohours 120 * 60

  defp post(body) do
    endpoint = @endpoint
    headers = ["content-type": "application/json; charset=utf-8"]
    options = [hackney: [basic_auth: {@user, @password}]]

    {:ok, %{body: body, status_code: 200}} =
      HTTPoison.post(endpoint, Jason.encode!(body), headers, options)

    %{"result" => result, "error" => nil} = Jason.decode!(body)
    result
  end

  defp latest_block_hash() do
    %{method: :getbestblockhash, params: []}
    |> post()
  end

  defp blockheader(hash) do
    %{method: :getblockheader, params: [hash, true]}
    |> post()
  end

  def start(hash \\ nil) do
    (hash || latest_block_hash())
    |> add_block(%{list: [], next_time: nil, start: nil})
  end

  defp add_block(hash, state) do
    %{"height" => height, "hash" => hash, "time" => time, "previousblockhash" => prev} =
      blockheader(hash)

    state =
      if state.next_time do
        interval = state.next_time - time

        if interval > @twohours do
          %{state | list: [{height + 1, interval} | state.list]}
        end
      else
        %{state | start: height}
      end || state

    IO.puts("added block: #{hash}, height: #{height}, found: #{length(state.list)}")

    if rem(height, 100_000) == 0 do
      log =
        "From the block height #{height} to #{state.start}, following blocks were mined more than 2 hours after previous block\n" <>
          for {h, t} <- Enum.sort_by(state.list, fn {_, t} -> -t end), into: <<>> do
            "block height: #{h}, interval: #{t} seconds\n"
          end

      File.write!("log", log, [:append])
    end

    if height != 0 do
      add_block(prev, %{state | next_time: time})
    end
  catch
    err, data ->
      IO.inspect({err, data})
      IO.puts("retry block: #{hash}, state: #{inspect(state)}")
      add_block(hash, state)
  end
end
