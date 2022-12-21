defmodule Transform do
  # Operation Transformation Functions
  import Emulation, only: [whoami: 0]

  # The GOT Control Algorithm
  #   Given a new causally ready operation op and a history buffer
  #   hb = [eop1, eop2, ..., eopm], return the execution form of op, denoted
  #   eop, which is obtained as follows:
  #     1. Scan hb from oldest to newest to find the first operation eopk that
  #        is independent of op. If no such operation exists, return op.
  #     2. Scan hb from k+1 to m to find all operations which are causally
  #        proceeding op. If no single operation is found, return list_it(op, hb[k, m]).
  #     3. Otherwise, let EOL = [eoc1, ..., eocr] be the list of operations
  #        in hb[k+1, m] which are causally proceeding op. Let EOL' be the
  #        list of operations of the corresponding form of EOL at the time of
  #        op's generation. Return list_it(list_et(op, EOL'), hb[k, m]).
  #  preconditions:
  #   - op is causallyr eady
  #   - hb is a history buffer with events ordered from newest to oldest
  @spec got(%OP{}, [%OP{}]) :: %OP{}
  def got(op, hb) do
    got1(op, Enum.reverse(hb))
  end

  # preconditions:
  #  - hb: history buffer sorted from oldest to newest
  defp got1(op, hb) do
    cond do
      hb == [] -> op
      independent?(op, hd(hb)) -> got2(op, hb)
      true -> got1(op, tl(hb))
    end
  end

  # preconditions:
  #  - hbk: hb[k, m], sorted from oldest to newest
  defp got2(op, hbk) do
    IO.puts("#{whoami()}: running got2, op: #{inspect(op)}, hbk: #{inspect(hbk)}")

    case Enum.filter(tl(hbk), &proceeding?(op, &1)) do
      [] -> list_it(op, hbk)
      _ -> got3(op, hbk)
    end
  end

  # preconditions:
  #  - hbk: hb[k, m], sorted from oldest to newest
  defp got3(op, hbk) do
    IO.puts("#{whoami()}: running got3, op: #{inspect(op)}, hbk: #{inspect(hbk)}")
    eolp = get_eolp(op, tl(hbk), [hd(hbk)], [])
    IO.puts("#{whoami()}: eolp: #{inspect(eolp)}")
    list_it(list_et(op, Enum.reverse(eolp)), hbk)
  end

  # preconditions:
  #  - hbi: hb[i, m], sorted from oldest to newest
  #  - hbc: hb[k, i], sorted from newest to oldest
  #  - eos: list of operations in hbc that are causally proceeding op
  defp get_eolp(op, hbi, hbc, eos) do
    cond do
      hbi == [] ->
        eos

      proceeding?(op, hd(hbi)) ->
        eo = hd(hbi)
        to = list_et(eo, hbc)
        eop = list_it(to, eos)
        get_eolp(op, tl(hbi), [eo | hbc], eos ++ [eop])

      true ->
        get_eolp(op, tl(hbi), [hd(hbi) | hbc], eos)
    end
  end

  # Helper functions for GOT

  # determine whether op1 is independet with op2
  defp independent?(op1, op2) do
    Clock.get_causal_order(op1.clock, op2.clock) == :concurrent
  end

  # determine whether op2 is causally proceeding op1
  defp proceeding?(op1, op2) do
    Clock.get_causal_order(op2.clock, op1.clock) == :before
  end

  # Inclusion transformation function
  #  precondition:
  #   - op1 and op2 are context equivalent
  #  postcondition:
  #   - op1' is context proceeding op2
  @spec it(%OP{}, %OP{}) :: %OP{}
  def it(op1, op2) do
    case {op1.operation, op2.operation} do
      {:insert, :insert} -> it_ii(op1, op2)
      {:insert, :delete} -> it_id(op1, op2)
      {:delete, :insert} -> it_di(op1, op2)
      {:delete, :delete} -> it_dd(op1, op2)
      {:identity, :insert} -> it_ti(op1, op2)
      # identity operation
      _ -> op1
    end
  end

  # Exclusion transformation function
  #  precondition:
  #   - op1 is context proceeding op2
  #  postcondition:
  #   - op1' is context equivalent to op2
  @spec et(%OP{}, %OP{}) :: %OP{}
  def et(op1, op2) do
    case {op1.operation, op2.operation} do
      {:insert, :insert} -> et_ii(op1, op2)
      {:insert, :delete} -> et_id(op1, op2)
      {:delete, :insert} -> et_di(op1, op2)
      {:delete, :delete} -> et_dd(op1, op2)
      {:identity, :delete} -> et_td(op1, op2)
      # identity operation
      _ -> op1
    end
  end

  # List inclusion transformation function
  #  precondition:
  #   - op and ops[0] are context equivalent
  #   - ops[i+1] is context proceeding ops[i] for all i
  #  postcondition:
  #   - op' is context proceeding ops[-1]
  @spec list_it(%OP{}, [%OP{}]) :: %OP{}
  def list_it(op, ops) do
    Enum.reduce(ops, op, fn op, acc -> it(acc, op) end)
  end

  # List exclusion transformation function
  #  precondition:
  #   - op is context proceeding ops[0]
  #   - ops[i] is context proceeding ops[i+1] for all i
  #  postcondition:
  #   - op' is context equivalent to ops[-1]
  @spec list_et(%OP{}, [%OP{}]) :: %OP{}
  def list_et(op, ops) do
    Enum.reduce(ops, op, fn op, acc -> et(acc, op) end)
  end

  # Individual transformation functions

  @spec it_ii(%OP{}, %OP{}) :: %OP{}
  defp it_ii(op1, op2) do
    cond do
      op1.index < op2.index -> op1
      op1.index >= op2.index -> %OP{op1 | index: op1.index + 1}
    end
  end

  @spec it_id(%OP{}, %OP{}) :: %OP{}
  defp it_id(op1, op2) do
    cond do
      op1.index <= op2.index -> op1
      op1.index > op2.index + 1 -> %OP{op1 | index: op1.index - 1}
      op1.index == op2.index + 1 -> %OP{op1 | base_ops: MapSet.put(op1.base_ops, op2.clock)}
    end
  end

  @spec it_di(%OP{}, %OP{}) :: %OP{}
  defp it_di(op1, op2) do
    cond do
      op1.index < op2.index -> op1
      op1.index >= op2.index -> %OP{op1 | index: op1.index + 1}
    end
  end

  @spec it_dd(%OP{}, %OP{}) :: %OP{}
  defp it_dd(op1, op2) do
    cond do
      op1.index < op2.index ->
        op1

      op1.index > op2.index ->
        %OP{op1 | index: op1.index - 1}

      op1.index == op2.index ->
        %OP{op1 | operation: :identity, base_ops: MapSet.put(op1.base_ops, op2.clock)}
    end
  end

  @spec et_ii(%OP{}, %OP{}) :: %OP{}
  defp et_ii(op1, op2) do
    cond do
      op1.index < op2.index -> op1
      true -> %OP{op1 | index: op1.index - 1}
    end
  end

  @spec et_id(%OP{}, %OP{}) :: %OP{}
  defp et_id(op1, op2) do
    cond do
      MapSet.member?(op1.base_ops, op2.clock) ->
        %OP{op1 | index: op1.index + 1, base_ops: MapSet.delete(op1.base_ops, op2.clock)}

      op1.index <= op2.index ->
        op1

      op1.index > op2.index ->
        %OP{op1 | index: op1.index + 1}
    end
  end

  @spec et_di(%OP{}, %OP{}) :: %OP{}
  defp et_di(op1, op2) do
    cond do
      op1.index < op2.index ->
        op1

      op1.index > op2.index ->
        %OP{op1 | index: op1.index - 1}

      op1.index == op2.index ->
        %OP{op1 | operation: :identity, base_ops: MapSet.put(op1.base_ops, op2.clock)}
    end
  end

  @spec et_dd(%OP{}, %OP{}) :: %OP{}
  defp et_dd(op1, op2) do
    cond do
      op1.index < op2.index ->
        op1

      op1.index > op2.index ->
        %OP{op1 | index: op1.index - 1}

      op1.index == op2.index ->
        %OP{op1 | operation: :identity, base_ops: MapSet.put(op1.base_ops, op2.clock)}
    end
  end

  @spec et_td(%OP{}, %OP{}) :: %OP{}
  defp et_td(op1, op2) do
    if MapSet.member?(op1.base_ops, op2.clock) do
      %OP{
        op1
        | operation: :delete,
          index: op2.index,
          base_ops: MapSet.delete(op1.base_ops, op2.clock)
      }
    else
      op1
    end
  end

  @spec it_ti(%OP{}, %OP{}) :: %OP{}
  defp it_ti(op1, op2) do
    if MapSet.member?(op1.base_ops, op2.clock) do
      %OP{
        op1
        | operation: :delete,
          index: op2.index,
          base_ops: MapSet.delete(op1.base_ops, op2.clock)
      }
    else
      op1
    end
  end
end
