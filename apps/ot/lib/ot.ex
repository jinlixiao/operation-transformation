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
    # The current count.
    count: nil,
    # The current document state.
    document: nil
  )

  @spec new_configuration([atom()]) :: %OT{}
  def new_configuration(view) do
    %OT{
      view: view,
      count: 0,
      document: ""
    }
  end

  # Increment the count.
  @spec inc(%OT{}) :: %OT{}
  defp inc(%OT{count: count} = configuration) do
    %OT{configuration | count: count + 1}
  end

  # Broadcast a message to all processes in the view.
  @spec broadcast(%OT{}, any()) :: [boolean()]
  defp broadcast(configuration, message) do
    me = whoami()

    configuration.view
    |> Enum.filter(fn x -> x != me end)
    |> Enum.map(fn x -> send(x, message) end)
  end

  @doc """
  Main Event Listener.
  """
  @spec loop(%OT{}) :: no_return()
  def loop(configuration) do
    receive do
      {sender, {:inc, editor}} ->
        IO.puts("Received incrementing count")

        if whoami() == editor do
          broadcast(configuration, {:inc, editor})
        end

        configuration = inc(configuration)
        loop(configuration)

      {sender, :get} ->
        IO.puts("Getting count")
        send(sender, configuration.count)
        loop(configuration)

      # Messages for debugging
      {sender, :send_document} ->
        IO.puts("Sending document")
        send(sender, configuration.document)
        loop(configuration)

      {sender, :send_count} ->
        IO.puts("Sending count, #{configuration.count}")
        send(sender, configuration.count)
        loop(configuration)
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> OT.hello()
      :world

  """
  def hello do
    :world
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
  Send a increment counter request to the Editor.
  """
  @spec inc(%Client{}) :: {:ok, %Client{}}
  def inc(client) do
    send(client.editor, {:inc, client.editor})
  end
end
