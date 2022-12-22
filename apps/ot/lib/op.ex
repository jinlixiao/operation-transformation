defmodule OP do
  # This module deals with operations.
  import Emulation, only: [whoami: 0]

  # The following functions deals with `op`, which is a tuple of the form:
  #  {clock, site, operation, text, index}
  #  - clock      (index 0): the vector clock of the operation; a map.
  #  - site       (index 1): the site that generated the operation; an atom.
  #  - operation  (index 2): the operation type, either :insert or :delete or :identity.
  #  - text       (index 3): the text of the operation; a string.
  #  - index      (index 4): the index of the operation; an integer.
  # op is also stored in the History Buffer (hb). So for :delete operations,
  # text is the deleted character. Note that for :insert operations, text is
  # the inserted text (non-modifiable).

  defstruct(
    clock: %{},
    site: nil,
    operation: nil,
    text: "",
    index: 0,
    base_ops: nil
  )

  @spec new(map(), atom(), atom(), String.t(), integer()) :: %OP{
          clock: map(),
          index: integer(),
          operation: atom(),
          site: atom(),
          text: String.t()
        }
  def new(clock, site, operation, text, index) do
    %OP{
      clock: clock,
      site: site,
      operation: operation,
      text: text,
      index: index,
      base_ops: MapSet.new()
    }
  end

  @spec exec_op(String.t(), [%OP{}], %OP{}) :: {String.t(), [%OP{}]}
  def exec_op(document, hb, op) do
    # undo_redo_op(document, hb, op)
    transform_undo_redo_op(document, hb, op)
  end

  # The Undo/Transform-do/Transform-redo algorithm.
  # Given a new causally ready operation op and hb = [eo1, ..., eom, ..., eon],
  # the following steps are executed:
  #  1. UNDO operations in hb which totally follow op to restore the document
  #     before their execution
  #  2. TRANSFORM op into eop by applying GOT control algorithm, and DO eop
  #  3. TRANSFORM each operation eo in hb[m+1, n] into new execution form eo'
  #     and then redo
  @spec transform_undo_redo_op(String.t(), [%OP{}], %OP{}) :: {String.t(), [%OP{}]}
  def transform_undo_redo_op(document, hb, op) do
    {document, hb, _, _} = transform_undo_redo_op_helper(document, hb, op)
    {document, hb}
  end

  defp transform_undo_redo_op_helper(document, hb, op) do
    cond do
      hb == [] || total_before_op?(hd(hb), op) ->
        eop = Transform.got(op, hb)
        IO.puts("#{whoami()}: Transformed #{inspect(op)} into #{inspect(eop)} via GOT")
        document = do_op(document, eop)
        IO.puts("#{whoami()}: Doing #{inspect(eop)}, result: '#{document}'")
        {document, [eop | hb], [eop], []}

      true ->
        op2 = hd(hb)
        document = undo_op(document, op2)
        IO.puts("#{whoami()}: Undoing #{inspect(op2)}, result: '#{document}'")
        {document, new_hb, eos, hbm} = transform_undo_redo_op_helper(document, tl(hb), op)
        eop2 = Transform.list_et(op2, hbm)
        eop2 = Transform.list_it(eop2, eos)
        IO.puts("#{whoami()}: hbm: #{inspect(hbm)}, eos: #{inspect(eos)}")
        IO.puts("#{whoami()}: Transformed #{inspect(op2)} into #{inspect(eop2)}")
        document = do_op(document, eop2)
        IO.puts("#{whoami()}: Doing #{inspect(op2)}, result: '#{document}'")
        {document, [eop2 | new_hb], eos ++ [eop2], [op2 | hbm]}
    end
  end

  # The Undo/Redo algorithm. When a new operation op is causally ready,
  # the following steps are executed:
  #  1. UNDO operations in HB which totally follow op to restore the document
  #     before their execution
  #  2. DO op
  #  3. REDO all operations that were undone from HB
  #
  # The implementation relies on one important invariant: operations in
  # HB are sorted according to their total order.
  @spec undo_redo_op(String.t(), [%OP{}], %OP{}) :: {String.t(), [%OP{}]}
  def undo_redo_op(document, hb, op) do
    cond do
      hb == [] || total_before_op?(hd(hb), op) ->
        document = do_op(document, op)
        {document, [op | hb]}

      true ->
        op2 = hd(hb)
        document = undo_op(document, op2)
        {document, new_hb} = undo_redo_op(document, tl(hb), op)
        document = do_op(document, op2)
        {document, [op2 | new_hb]}
    end
  end

  # Do an operation on a document.
  # Returns the new document and the operation.
  # If the operation is a :delete operation, the deleted character is stored.
  @spec do_op(String.t(), %OP{}) :: String.t()
  defp do_op(document, op) do
    case op.operation do
      :insert ->
        insert(document, op.text, op.index)

      :delete ->
        delete(document, op.index)

      :identity ->
        document
    end
  end

  # Undo an operation on a document.
  # Returns the new document and the operation.
  @spec undo_op(String.t(), %OP{}) :: String.t()
  defp undo_op(document, op) do
    case op.operation do
      :insert ->
        delete(document, op.index)

      :delete ->
        insert(document, op.text, op.index)

      :identity ->
        document
    end
  end

  # Return true if op1 is totally before op2, false otherwise
  @spec total_before_op?(%OP{}, %OP{}) :: boolean()
  defp total_before_op?(op1, op2) do
    Clock.get_total_order(op1.clock, op1.site, op2.clock, op2.site) == :before
  end

  # The following functions are used to manipulate the document.

  # Insert a string at a given index.
  # Here we use a naive implementation of string concatenation.
  @spec insert(String.t(), String.t(), integer()) :: String.t()
  defp insert(document, text, index) do
    {head, tail} = String.split_at(document, index)
    res = head <> text <> tail
    res
  end

  # Delete a character at a given index.
  # Here we use a naive implementation of string concatenation.
  @spec delete(String.t(), integer()) :: String.t()
  defp delete(document, index) do
    {head, tail} = String.split_at(document, index)
    res = head <> String.slice(tail, 1..String.length(tail)//1)
    res
  end
end

defimpl Inspect, for: OP do
  def inspect(op, _opts) do
    # clock = "#{op.clock.a},#{op.clock.b},#{op.clock.c}"
    clock = ""

    case op.operation do
      :insert -> "insert(:#{op.site}, '#{op.text}', #{op.index})" <> clock
      :delete -> "delete(:#{op.site}, '#{op.text}', #{op.index})" <> clock
      :identity -> "identity()" <> clock
    end
  end
end
