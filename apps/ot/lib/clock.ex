defmodule Clock do
  # Compare the causal order of c1 and c2
  # Return values:
  #  * :before      c1 is causally before c2.
  #  * :after       c1 is causally after c2.
  #  * :concurrent  c1 and c2 are concurrent.
  @spec get_causal_order(map(), map()) :: :before | :after | :concurrent
  def get_causal_order(c1, c2) do
    compare_result =
      Map.values(
        Map.merge(c1, c2, fn _k, t1, t2 ->
          cond do
            t1 < t2 -> :before
            t1 > t2 -> :after
            true -> :concurrent
          end
        end)
      )
      |> Enum.filter(fn x -> x != :concurrent end)

    cond do
      Enum.all?(compare_result, fn x -> x == :before end) -> :before
      Enum.all?(compare_result, fn x -> x == :after end) -> :after
      true -> :concurrent
    end
  end

  # Compare the total order of c1 (originated at site s1) and c2 (originated at site s2)
  # Return values:
  #  * :before      c1 is total before c2.
  #  * :after       c1 is total after c2.
  #  * :concurrent  c1 and c2 are concurrent.
  @spec get_total_order(map(), atom(), map(), atom()) ::
          :before | :after | :concurrent
  def get_total_order(c1, s1, c2, s2) do
    causal_order = get_causal_order(c1, c2)

    if causal_order != :concurrent do
      causal_order
    else
      sum1 = Enum.sum(Map.values(c1))
      sum2 = Enum.sum(Map.values(c2))

      cond do
        sum1 < sum2 -> :before
        sum1 > sum2 -> :after
        s1 < s2 -> :before
        s1 > s2 -> :after
        true -> :concurrent
      end
    end
  end

  # Combine vector clocks.
  @spec combine_clock(map(), map()) :: map
  def combine_clock(c1, c2) do
    Map.merge(c1, c2, fn _k, v1, v2 -> max(v1, v2) end)
  end

  # Increment the clock of a site.
  @spec tick(map(), integer()) :: map
  def tick(clock, site) do
    Map.update(clock, site, 0, fn v -> v + 1 end)
  end
end
