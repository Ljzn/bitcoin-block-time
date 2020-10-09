defmodule Q1 do
  @moduledoc """
  Documentation for `Q1`.
  """

  # Probability of a block in this minute
  @b 1 / 10
  # Number of consecutive minutes without block
  @t 120

  # In n minutes, the probability that the block interval exceeds t minutes
  def p(n) when n >= 0 and n < @t, do: 0
  def p(n) when n == @t, do: cache(n, fn -> :math.pow(1 - @b, @t) end)

  def p(n) when n > @t,
    do: cache(n, fn -> p(n - 1) + (1 - p(n - @t - 1)) * @b * :math.pow(1 - @b, @t) end)

  defp cache(k, f) do
    case Process.get(k) do
      nil ->
        v = f.()
        Process.put(k, v)
        v

      v ->
        v
    end
  end

  def year(x), do: 60 * 24 * 365 * x

  # > p(year(1))
  # 0.15608225850734098
  # > p(year(10))
  # 0.8168266364519111
end
