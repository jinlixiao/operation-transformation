defmodule OT do
  @moduledoc """
  An implementation of the Operational Transformation algorithm.
  """

  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  require Logger
  require Transform

  defstruct(
    # The list of current proceses.
    view: nil,
    # The current document state.
    document: nil,
    # The current vector clock.
    clock: nil,
    # history buffer keeping track of all executed operations.
    hb: nil
  )

  @spec new_configuration([atom()]) :: %OT{}
  def new_configuration(view) do
    %OT{
      view: view,
      document: "",
      clock: Map.new(view, fn x -> {x, 0} end),
      hb: []
    }
  end

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

  # Broadcast a message to all processes in the view.
  @spec broadcast(%OT{}, any()) :: [boolean()]
  defp broadcast(configuration, message) do
    me = whoami()

    configuration.view
    |> Enum.filter(fn x -> x != me end)
    |> Enum.map(fn x -> send(x, message) end)
  end

  # Update clock value for a given site.
  @spec tick(%OT{}, atom()) :: %OT{}
  defp tick(configuration, site) do
    %OT{configuration | clock: Map.update(configuration.clock, site, 0, &(&1 + 1))}
  end

  # Combine vector clocks.
  defp combine_clock(configuration, clock) do
    %OT{
      configuration
      | clock: Map.merge(configuration.clock, clock, fn _k, v1, v2 -> max(v1, v2) end)
    }
  end

  # Check if an received operation is ready to be executed.
  #  * configuration: the current configuration.
  #  * clock: the clock of the received operation.
  #  * site: the generation site of the received operation.
  @spec casually_ready?(%OT{}, map(), atom()) :: boolean()
  defp casually_ready?(configuration, clock, site) do
    configuration.clock[site] + 1 == clock[site] and
      configuration.view
      |> Enum.filter(fn x -> x != site end)
      |> Enum.all?(fn x -> configuration.clock[x] >= clock[x] end)
  end

  # Compare the causal order of c1 and c2
  # Return values:
  #  * :before      c1 is causally before c2.
  #  * :after       c1 is causally after c2.
  #  * :concurrent  c1 and c2 are concurrent.
  @spec get_causal_order(map(), map()) :: :before | :after | :concurrent
  defp get_causal_order(c1, c2) do
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
  @spec get_total_order(map(), atom(), map(), atom()) :: :before | :after | :concurrent
  defp get_total_order(c1, s1, c2, s2) do
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

  # Add an operation to the history buffer.
  #  * configuration: the current configuration.
  #  * op: the operation tuple
  @spec hb_add(%OT{}, any()) :: %OT{}
  defp hb_add(configuration, op) do
    %OT{configuration | hb: [op | configuration.hb]}
  end

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
    get_total_order(elem(op1, 0), elem(op1, 1), elem(op2, 0), elem(op2, 1)) == :before
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
  defp undo_redo_op(document, hb, op) do
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

  # Execute an insert operation. The operation needed to be causally ready.
  defp exec_insert(configuration, clock, site, text, index) do
    IO.puts(
      "#{whoami()}: Executing insert '#{text}' at index #{index} with clock #{inspect(clock)}"
    )

    {document, hb} =
      undo_redo_op(configuration.document, configuration.hb, {clock, site, :insert, text, index})

    configuration = %OT{configuration | document: document, hb: hb}
    tick(configuration, site)
  end

  # Execute a delete operation. The operation needed to be causally ready.
  defp exec_delete(configuration, clock, site, index) do
    IO.puts("#{whoami()}: Executing delete at index #{index} with clock #{inspect(clock)}")

    {document, hb} =
      undo_redo_op(configuration.document, configuration.hb, {clock, site, :delete, "", index})

    configuration = %OT{configuration | document: document, hb: hb}
    tick(configuration, site)
  end

  defp gen_insert(configuration, text, index) do
    op_clock = tick(configuration, whoami()).clock
    broadcast(configuration, {:insert, op_clock, whoami(), text, index})
    op_clock
  end

  defp gen_delete(configuration, index) do
    op_clock = tick(configuration, whoami()).clock
    broadcast(configuration, {:delete, op_clock, whoami(), index})
    op_clock
  end

  @doc """
  Main Event Listener.
  """
  @spec loop(%OT{}) :: no_return()
  def loop(configuration) do
    receive do
      # Messages from editor cleints.
      {_sender, {:insert_client, text, index, _clock}} ->
        IO.puts(
          "#{whoami()}: Received insert req from client, inserting #{text} at index #{index}"
        )

        op_clock = gen_insert(configuration, text, index)
        configuration = exec_insert(configuration, op_clock, whoami(), text, index)
        loop(configuration)

      {_sender, {:delete_client, index, _clock}} ->
        IO.puts("#{whoami()}: Received delete req from client, deleting at index #{index}")

        op_clock = gen_delete(configuration, index)
        configuration = exec_delete(configuration, op_clock, whoami(), index)
        loop(configuration)

      # Messages from other processes.
      {sender, {:insert, clock, site, text, index}} ->
        IO.puts(
          "#{whoami()}: Received insert req from #{sender}, inserting '#{text}' at index #{index} with SV #{inspect(clock)}"
        )

        if casually_ready?(configuration, clock, site) do
          configuration = exec_insert(configuration, clock, site, text, index)
          loop(configuration)
        else
          send(whoami(), {:insert, clock, site, text, index})
          loop(configuration)
        end

      {sender, {:delete, clock, site, index}} ->
        IO.puts(
          "#{whoami()}: Received delete req from #{sender}, deleting at index #{index} with SV #{inspect(clock)}"
        )

        if casually_ready?(configuration, clock, site) do
          configuration = exec_delete(configuration, clock, site, index)
          loop(configuration)
        else
          send(whoami(), {:delete, clock, site, index})
          loop(configuration)
        end

      # Messages for debugging
      {sender, :send_document} ->
        IO.puts("#{whoami()}: Sending document...")
        send(sender, configuration.document)
        loop(configuration)

      {sender, :send_clock} ->
        IO.puts("#{whoami()}: Sending clock...")
        send(sender, configuration.clock)
        loop(configuration)

      {sender, :send_state} ->
        IO.puts("#{whoami()}: Sending state...")
        send(sender, {configuration.document, configuration.clock})
        loop(configuration)
    end
  end
end

defmodule OT.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to the RSM.
  """
  alias __MODULE__
  @enforce_keys [:editor]
  defstruct(editor: nil)

  @doc """
  Construct a new Editor Client. This takes an ID of the
  editor that the client will be connected to.
  """
  @spec new_client(atom()) :: %Client{editor: atom()}
  def new_client(proc) do
    %Client{editor: proc}
  end

  @doc """
  Send a insert request to the Editor.
  """
  def insert(client, text, index, clock) do
    send(client.editor, {:insert_client, text, index, clock})
  end

  @doc """
  Send a delete request to the Editor.
  """
  def delete(client, index, clock) do
    send(client.editor, {:delete_client, index, clock})
  end
end
