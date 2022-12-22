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

  test "eventual consistency I" do
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
        client_c = OT.Client.new_client(:c)
        OT.Client.insert(client_a, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "c", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_c, 0, Map.new(view, fn x -> {x, 0} end))

        Process.sleep(1000)
        view |> Enum.map(fn x -> send(x, :send_document) end)

        documents =
          view
          |> Enum.map(fn x ->
            receive do
              {^x, document} -> document
            end
          end)

        assert Enum.all?(documents, fn x -> x == hd(documents) end)
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

  test "eventual consistency II" do
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
        OT.Client.insert(client_b, "b", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "c", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "d", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_c, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "f", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "e", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "g", 1, Map.new(view, fn x -> {x, 0} end))
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

        assert Enum.all?(documents, fn x -> x == hd(documents) end)
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

  test "eventual consistency III" do
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
        OT.Client.insert(client_b, "b", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "c", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "d", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_c, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "f", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "e", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "g", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "b", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "c", 3, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "d", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_c, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "f", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "e", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "g", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "a", 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "b", 2, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "c", 3, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "d", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_c, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.delete(client_a, 0, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_c, "f", 4, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_a, "e", 1, Map.new(view, fn x -> {x, 0} end))
        OT.Client.insert(client_b, "g", 3, Map.new(view, fn x -> {x, 0} end))
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

        assert Enum.all?(documents, fn x -> x == hd(documents) end)
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

  test "intention preservation I" do
    Emulation.init()

    base_config = OT.new_configuration([:a, :b])

    spawn(:a, fn -> OT.loop(base_config) end)

    client =
      spawn(:client, fn ->
        send(:a, OP.new(%{a: 1, b: 0}, :a, :insert, "a", 0))
        send(:a, OP.new(%{a: 2, b: 0}, :a, :delete, "a", 0))
        send(:a, OP.new(%{a: 1, b: 1}, :b, :insert, "b", 0))
        send(:a, OP.new(%{a: 1, b: 2}, :b, :delete, "b", 0))

        send(:a, :send_document)

        document =
          receive do
            {:a, document} -> document
          end

        assert document == ""
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

  test "intention preservation II" do
    Emulation.init()

    base_config = OT.new_configuration([:a, :b, :c])

    spawn(:a, fn -> OT.loop(base_config) end)

    client =
      spawn(:client, fn ->
        # ""
        send(:a, OP.new(%{a: 1, b: 0, c: 0}, :a, :insert, "a", 0))
        # "a"
        send(:a, OP.new(%{a: 0, b: 0, c: 1}, :c, :insert, "c", 0))
        # "ac"
        send(:a, OP.new(%{a: 2, b: 0, c: 1}, :a, :delete, "a", 0))
        # "c"
        send(:a, OP.new(%{a: 0, b: 1, c: 0}, :b, :insert, "b", 0))
        # "bc"
        send(:a, OP.new(%{a: 0, b: 1, c: 2}, :c, :insert, "d", 1))
        # "bdc"
        send(:a, OP.new(%{a: 3, b: 1, c: 2}, :a, :insert, "e", 1))
        # "bedc"
        send(:a, OP.new(%{a: 4, b: 1, c: 2}, :a, :delete, "e", 1))
        # "bdc"
        send(:a, OP.new(%{a: 1, b: 1, c: 3}, :c, :delete, "a", 0))
        # "bdc"
        send(:a, OP.new(%{a: 1, b: 2, c: 0}, :b, :insert, "g", 1))
        # "bgdc"
        send(:a, :send_document)

        document =
          receive do
            {:a, document} -> document
          end

        assert document == "bgdc"
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
