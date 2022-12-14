defmodule Transform do
  # Operation Transformation Functions

  # The following functions deals with `op`, which is a tuple of the form:
  #  {clock, site, operation, text, index}
  #  - clock      (index 0): the vector clock of the operation; a map.
  #  - site       (index 1): the site that generated the operation; an atom.
  #  - operation  (index 2): the operation type, either :insert or :delete.
  #  - text       (index 3): the text of the operation; a string.
  #  - index      (index 4): the index of the operation; an integer.
  # op is also stored in the History Buffer (hb). So for :delete operations,
  # text is the deleted character. Note that for :insert operations, text is
  # the inserted text (non-modifiable).

  # The GOT Control Algorithm
  #   Given a new causally ready operation op and a history buffer
  #   hb = [eop1, eop2, ..., eopm], return the execution form of op, denoted
  #   eop, which is obtained as follows:
  #     1. Scan hb from oldest to newest to find the first operation eopk that
  #        is independent of op. If no such operation exists, return op.
  #     2. Scan hb from eopk+1 to m to find all operations which are causally
  #        proceeding op. If no single operation is found, return list_it(op, hb[k, m]).
  #     3. Otherwise, let EOL = [eoc1, ..., eocr] be the list of operations
  #        in hb[k+1, m] which are causally proceeding op. Let EOL' be the
  #        list of operations of the corresponding form of EOL at the time of
  #        op's generation. Return list_it(list_et(op, EOL'), hb[k, m]).
  def got(op, hb) do
    # TODO: implement this function
  end

  # Inclusion transformation function
  #  precondition:
  #   - op1 and op2 are context equivalent
  #  postcondition:
  #   - op1' is context proceeding op2
  @spec it(tuple(), tuple()) :: tuple()
  def it(op1, op2) do
    case {elem(op1, 2), elem(op2, 2)} do
      {:insert, :insert} -> it_ii(op1, op2)
      {:insert, :delete} -> it_id(op1, op2)
      {:delete, :insert} -> it_di(op1, op2)
      {:delete, :delete} -> it_dd(op1, op2)
      # identity operation
      _ -> op1
    end
  end

  # Exclusion transformation function
  #  precondition:
  #   - op1 is context proceeding op2
  #  postcondition:
  #   - op1' is context equivalent to op2
  @spec et(tuple(), tuple()) :: tuple()
  def et(op1, op2) do
    case {elem(op1, 2), elem(op2, 2)} do
      {:insert, :insert} -> et_ii(op1, op2)
      {:insert, :delete} -> et_id(op1, op2)
      {:delete, :insert} -> et_di(op1, op2)
      {:delete, :delete} -> et_dd(op1, op2)
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
  @spec list_it(any(), any()) :: any()
  def list_it(op, ops) do
    Enum.reduce(ops, op, fn op, acc -> it(op, acc) end)
  end

  # List exclusion transformation function
  #  precondition:
  #   - op is context proceeding ops[0]
  #   - ops[i] is context proceeding ops[i+1] for all i
  #  postcondition:
  #   - op' is context equivalent to ops[-1]
  @spec list_et(any(), any()) :: any()
  def list_et(op, ops) do
    Enum.reduce(ops, op, fn op, acc -> et(op, acc) end)
  end

  # Individual transformation functions

  defp it_ii(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      true -> put_elem(op1, 4, p1 + 1)
    end
  end

  defp it_id(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 <= p2 -> op1
      true -> put_elem(op1, 4, p1 - 1)
    end
  end

  defp it_di(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      true -> put_elem(op1, 4, p1 + 1)
    end
  end

  defp it_dd(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      p1 > p2 -> put_elem(op1, 4, p1 + 1)
      true -> put_elem(op1, 2, :identity)
    end
  end

  defp et_ii(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      true -> put_elem(op1, 4, p1 - 1)
    end
  end

  defp et_id(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      true -> put_elem(op1, 4, p1 + 1)
    end
  end

  defp et_di(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 <= p2 -> op1
      true -> put_elem(op1, 4, p1 - 1)
    end
  end

  defp et_dd(op1, op2) do
    p1 = elem(op1, 4)
    p2 = elem(op2, 4)

    cond do
      p1 < p2 -> op1
      p1 > p2 -> put_elem(op1, 4, p1 - 1)
      true -> put_elem(op1, 2, :identity)
    end
  end
end
