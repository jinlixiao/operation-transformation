defmodule OP do
  # This module deals with operations.

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
    index: 0
  )

  def new(clock, site, operation, text, index) do
    %OP{
      clock: clock,
      site: site,
      operation: operation,
      text: text,
      index: index
    }
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
  @spec undo_redo_op(String.t(), list(), any()) :: {String.t(), list()}
  def undo_redo_op(document, hb, op) do
    cond do
      hb == [] || total_before_op?(hd(hb), op) ->
        {document, op} = do_op(document, op)
        {document, [op | hb]}

      true ->
        op2 = hd(hb)
        {document, op2} = undo_op(document, op2)
        {document, new_hb} = undo_redo_op(document, tl(hb), op)
        {document, op2} = do_op(document, op2)
        {document, [op2 | new_hb]}
    end
  end

  # Do an operation on a document.
  # Returns the new document and the operation.
  # If the operation is a :delete operation, the deleted character is stored.
  @spec do_op(String.t(), any()) :: {String.t(), any()}
  defp do_op(document, op) do
    case elem(op, 2) do
      :insert ->
        {insert(document, elem(op, 3), elem(op, 4)), op}

      :delete ->
        {document, deleted} = delete(document, elem(op, 4))
        {document, put_elem(op, 3, deleted)}

      :identity ->
        {document, op}
    end
  end

  # Undo an operation on a document.
  # Returns the new document and the operation.
  @spec undo_op(String.t(), any()) :: {String.t(), any()}
  defp undo_op(document, op) do
    case elem(op, 2) do
      :insert ->
        {document, _} = delete(document, elem(op, 4))
        {document, op}

      :delete ->
        {insert(document, elem(op, 3), elem(op, 4)), op}

      :identity ->
        {document, op}
    end
  end

  # Return true if op1 is totally before op2, false otherwise
  @spec total_before_op?(any(), any()) :: boolean()
  defp total_before_op?(op1, op2) do
    Clock.get_total_order(elem(op1, 0), elem(op1, 1), elem(op2, 0), elem(op2, 1)) == :before
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
  @spec delete(String.t(), integer()) :: {String.t(), String.t()}
  defp delete(document, index) do
    {head, tail} = String.split_at(document, index)
    res = head <> String.slice(tail, 1..String.length(tail)//1)
    {res, String.at(tail, 0)}
  end
end
