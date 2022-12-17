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
  require Clock

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
    %OT{configuration | clock: Clock.tick(configuration.clock, site)}
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

  # Execute an insert operation. The operation needed to be causally ready.
  defp exec_insert(configuration, clock, site, text, index) do
    IO.puts(
      "#{whoami()}: Executing insert '#{text}' at index #{index} with clock #{inspect(clock)}"
    )

    {document, hb} =
      OP.undo_redo_op(
        configuration.document,
        configuration.hb,
        {clock, site, :insert, text, index}
      )

    configuration = %OT{configuration | document: document, hb: hb}
    tick(configuration, site)
  end

  # Execute a delete operation. The operation needed to be causally ready.
  defp exec_delete(configuration, clock, site, index) do
    IO.puts("#{whoami()}: Executing delete at index #{index} with clock #{inspect(clock)}")

    {document, hb} =
      OP.undo_redo_op(configuration.document, configuration.hb, {clock, site, :delete, "", index})

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
