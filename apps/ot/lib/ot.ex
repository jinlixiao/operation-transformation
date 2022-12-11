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

  # Combine vector clocks.
  defp combine_clock(configuration, clock) do
    %OT{
      configuration
      | clock: Map.merge(configuration.clock, clock, fn _k, v1, v2 -> max(v1, v2) end)
    }
  end

  defp get_casuality(configuration, clock) do
    happen_before? =
      Enum.all?(Map.keys(configuration.clock), fn x ->
        Map.get(configuration.clock, x) <= Map.get(clock, x)
      end)

    happen_after? =
      Enum.all?(Map.keys(clock), fn x ->
        Map.get(configuration.clock, x) >= Map.get(clock, x)
      end)

    cond do
      happen_before? -> :happen_before
      happen_after? -> :happen_after
      true -> :independent
    end
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

        configuration = tick(configuration)
        configuration = combine_clock(configuration, clock)
        IO.puts("#{whoami()}: Clock is now #{inspect(configuration.clock)}")
        broadcast(configuration, {:insert, text, index, configuration.clock})
        configuration = insert(configuration, text, index)
        loop(configuration)

      {_sender, {:delete_client, index, clock}} ->
        IO.puts("#{whoami()}: Received delete req from client, deleting at index #{index}")
        configuration = tick(configuration)
        configuration = combine_clock(configuration, clock)
        IO.puts("#{whoami()}: Clock is now #{inspect(configuration.clock)}")
        broadcast(configuration, {:delete, index, configuration.clock})
        configuration = delete(configuration, index)
        loop(configuration)

      # Messages from other processes.
      {sender, {:insert, text, index, clock}} ->
        IO.puts(
          "#{whoami()}: Received insert req from #{sender}, inserting '#{text}' at index #{index}"
        )

        configuration = tick(configuration)
        configuration = combine_clock(configuration, clock)
        IO.puts("#{whoami()}: Clock is now #{inspect(configuration.clock)}")
        configuration = insert(configuration, text, index)
        loop(configuration)

      {sender, {:delete, index, clock}} ->
        IO.puts("#{whoami()}: Received delete req from #{sender}, deleting at index #{index}")
        configuration = tick(configuration)
        configuration = combine_clock(configuration, clock)
        IO.puts("#{whoami()}: Clock is now #{inspect(configuration.clock)}")
        configuration = delete(configuration, index)
        loop(configuration)

      # Messages for debugging
      {sender, :send_document} ->
        IO.puts("#{whoami()}: Sending document")
        send(sender, configuration.document)
        loop(configuration)

      {sender, :send_clock} ->
        IO.puts("#{whoami()}: Sending clock")
        send(sender, configuration.clock)
        loop(configuration)

      {sender, :send_state} ->
        IO.puts("#{whoami()}: Sending state")
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
