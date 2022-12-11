defmodule OTTest do
  use ExUnit.Case
  doctest OT

  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "basic insert and delete" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(2)])

    base_config = OT.new_configuration([:a, :b, :c])

    spawn(:a, fn -> OT.loop(base_config) end)
    spawn(:b, fn -> OT.loop(base_config) end)
    spawn(:c, fn -> OT.loop(base_config) end)

    client =
      spawn(:client, fn ->
        view = [:a, :b, :c]
        client_a = OT.Client.new_client(:a)
        OT.Client.insert(client_a, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "b", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "c", 0, Map.new(view, fn x -> {x, 0} end))

        Process.sleep(1000)
        view |> Enum.map(fn x -> send(x, :send_document) end)

        documents =
          view
          |> Enum.map(fn x ->
            receive do
              {^x, document} -> document
            end
          end)

        assert Enum.all?(documents, fn x -> x == "cab" end)

        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 1, Map.new(view, fn x -> {x, 0} end))

        Process.sleep(1000)
        view |> Enum.map(fn x -> send(x, :send_document) end)

        documents =
          view
          |> Enum.map(fn x ->
            receive do
              {^x, document} -> document
            end
          end)

        assert Enum.all?(documents, fn x -> x == "a" end)
      end)

    handle = Process.monitor(client)
    # Timeout.
    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end

  test "basic insert with broadcast" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(2)])

    base_config = OT.new_configuration([:a, :b, :c])

    spawn(:a, fn -> OT.loop(base_config) end)
    spawn(:b, fn -> OT.loop(base_config) end)
    spawn(:c, fn -> OT.loop(base_config) end)

    client =
      spawn(:client, fn ->
        view = [:a, :b, :c]
        client_a = OT.Client.new_client(:a)
        client_b = OT.Client.new_client(:b)
        client_c = OT.Client.new_client(:c)
        OT.Client.insert(client_a, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "a", 0, Map.new(view, fn x -> {x, 0} end))

        Process.sleep(1000)
        view |> Enum.map(fn x -> send(x, :send_document) end)

        documents =
          view
          |> Enum.map(fn x ->
            receive do
              {^x, document} -> document
            end
          end)

        assert Enum.all?(documents, fn x -> x == "aaa" end)
      end)

    handle = Process.monitor(client)
    # Timeout.
    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end
end
