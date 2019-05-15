defmodule MultixTest do
  use ExUnit.Case, async: false
  doctest Multix

  test "basic test get works" do
    name = :test1
    {:ok, _} = Server.Sup.start_link(name: name)
    counters = for i <- 1..4, into: %{}, do: {i, 0}

    for _ <- 1..20, reduce: counters do
      counters ->
        assert {{_, count_id}, count} = Server.count(name)
        assert count == counters[count_id]
        Map.update!(counters, count_id, &(&1 + 1))
    end
  end

  test "test works with failures and restores" do
    name = :test2
    {:ok, _} = Server.Sup.start_link(name: name)
    counters = for i <- 1..4, into: %{}, do: {i, 0}

    for _ <- 1..100, reduce: {1, counters} do
      {old_id, counters} ->
        id = rem(old_id, 4) + 1
        Server.disable({name, id})
        Server.enable({name, old_id})

        assert :error = Server.count({name, id})
        assert {{_, count_id}, count} = count(name)
        assert count == counters[count_id]

        {id, Map.update!(counters, count_id, &(&1 + 1))}
    end
  end

  defp count(name) do
    case Server.count(name) do
      nil ->
        # temporary all servers can be unavailable
        :timer.sleep(50)
        count(name)

      result ->
        result
    end
  end
end
