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
    clock: nil
  )

  @spec new_configuration([atom()]) :: %OT{}
  def new_configuration(view) do
    %OT{
      view: view,
      document: "",
      clock: Map.new(view, fn x -> {x, 0} end)
    }
  end

  # Insert a string at a given index.
  # Here we use a naive implementation of string concatenation.
  @spec insert(%OT{}, String.t(), integer()) :: %OT{}
  defp insert(%OT{document: document} = configuration, text, index) do
    {head, tail} = String.split_at(document, index)
    res = head <> text <> tail
    %OT{configuration | document: res}
  end

  # Delete a character at a given index.
  # Here we use a naive implementation of string concatenation.
  @spec delete(%OT{}, integer()) :: %OT{}
  defp delete(%OT{document: document} = configuration, index) do
    {head, tail} = String.split_at(document, index)
    res = head <> String.slice(tail, 1..String.length(tail)//1)
    %OT{configuration | document: res}
  end

  # Broadcast a message to all processes in the view.
  @spec broadcast(%OT{}, any()) :: [boolean()]
  defp broadcast(configuration, message) do
    me = whoami()

    configuration.view
    |> Enum.filter(fn x -> x != me end)
    |> Enum.map(fn x -> send(x, message) end)
  end

  # Update clock value.
  @spec tick(%OT{}) :: %OT{}
  defp tick(configuration) do
    me = whoami()
    %OT{configuration | clock: Map.update(configuration.clock, me, 0, &(&1 + 1))}
  end

  @doc """
  Main Event Listener.
  """
  @spec loop(%OT{}) :: no_return()
  def loop(configuration) do
    receive do
      {_sender, {:insert, editor, text, index}} ->
        IO.puts("Received insert")

        if whoami() == editor do
          broadcast(configuration, {:insert, editor, text, index})
        end

        configuration = insert(configuration, text, index)
        loop(configuration)

      {_sender, {:delete, editor, index}} ->
        IO.puts("Received delete")

        if whoami() == editor do
          broadcast(configuration, {:delete, editor, index})
        end

        configuration = delete(configuration, index)
        loop(configuration)

      # Messages for debugging
      {sender, :send_document} ->
        IO.puts("Sending document")
        send(sender, configuration.document)
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
  @spec insert(atom | %{:editor => atom | pid, optional(any) => any}, any, any) :: boolean
  def insert(client, text, index) do
    send(client.editor, {:insert, client.editor, text, index})
  end

  @doc """
  Send a delete request to the Editor.
  """
  @spec delete(atom | %{:editor => atom | pid, optional(any) => any}, any) :: boolean
  def delete(client, index) do
    send(client.editor, {:delete, client.editor, index})
  end
end
