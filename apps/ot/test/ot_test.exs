defmodule OTTest do
  use ExUnit.Case
  doctest OT

  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "greets the world" do
    assert OT.hello() == :world
  end

  test "basic increment" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(2)])

    base_config = OT.new_configuration([:a, :b, :c])

    spawn(:a, fn -> OT.loop(base_config) end)
    spawn(:b, fn -> OT.loop(base_config) end)
    spawn(:c, fn -> OT.loop(base_config) end)

    client =
      spawn(:client, fn ->
        client = OT.Client.new_client(:a)
        OT.Client.inc(client)
        send(:a, :send_count)

        receive do
          {sender, count} -> assert count == 1
        end
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

  test "basic increment with broadcast" do
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
        OT.Client.inc(client_a)
        OT.Client.inc(client_b)
        OT.Client.inc(client_a)
        OT.Client.inc(client_c)

        Process.sleep(1000)
        view |> Enum.map(fn x -> send(x, :send_count) end)

        counts =
          view
          |> Enum.map(fn x ->
            receive do
              {^x, count} -> count
            end
          end)

        assert Enum.all?(counts, fn x -> x == 4 end)
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
