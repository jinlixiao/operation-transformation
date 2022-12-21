defmodule OT do
  @moduledoc """
  An implementation of the Operational Transformation algorithm.
  """

  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  require Logger

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

  @spec new_configuration(any) :: %OT{
          clock: map(),
          document: String.t(),
          hb: [%OP{}],
          view: [atom()]
        }
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

  # Check if an received operation is ready to be executed.
  #  * configuration: the current configuration.
  #  * clock: the clock of the received operation.
  #  * site: the generation site of the received operation.
  @spec casually_ready?(%OT{}, %OP{}) :: boolean()
  defp casually_ready?(configuration, op) do
    site = op.site
    clock = op.clock

    configuration.clock[site] + 1 == clock[site] and
      configuration.view
      |> Enum.filter(fn x -> x != site end)
      |> Enum.all?(fn x -> configuration.clock[x] >= clock[x] end)
  end

  @spec execute_op(%OT{}, %OP{}) :: %OT{}
  defp execute_op(configuration, op) do
    {document, hb} = OP.exec_op(configuration.document, configuration.hb, op)
    clock = Clock.tick(configuration.clock, op.site)
    %OT{configuration | document: document, hb: hb, clock: clock}
  end

  @doc """
  Main Event Listener.
  """
  @spec loop(%OT{}) :: no_return()
  def loop(configuration) do
    receive do
      # Messages from editor cleints.
      {_sender, {:insert_client, text, index, clock}} ->
        IO.puts(
          "#{whoami()}: Received insert req from client, inserting #{text} at index #{index}"
        )

        if index > String.length(configuration.document) do
          send(whoami(), {:insert_client, text, index, clock})
          loop(configuration)
        else
          op = OP.new(Clock.tick(configuration.clock, whoami()), whoami(), :insert, text, index)
          broadcast(configuration, op)
          configuration = execute_op(configuration, op)
          loop(configuration)
        end

      {_sender, {:delete_client, index, clock}} ->
        IO.puts("#{whoami()}: Received delete req from client, deleting at index #{index}")

        if index > String.length(configuration.document) do
          send(whoami(), {:delete_client, index, clock})
          loop(configuration)
        else
          op = OP.new(Clock.tick(configuration.clock, whoami()), whoami(), :delete, "", index)
          broadcast(configuration, op)
          configuration = execute_op(configuration, op)
          loop(configuration)
        end

      # Messages from other processes.
      {_sender, %OP{} = op} ->
        if casually_ready?(configuration, op) do
          configuration = execute_op(configuration, op)
          loop(configuration)
        else
          send(whoami(), op)
          loop(configuration)
        end

      # Messages for debugging
      {sender, :send_document} ->
        send(sender, configuration.document)
        loop(configuration)

      {sender, :send_clock} ->
        send(sender, configuration.clock)
        loop(configuration)

      {sender, :send_state} ->
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
