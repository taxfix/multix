defmodule Server do
  use GenServer

  require Logger

  @behaviour Multix.OnFailure

  def child_spec(opts) do
    id = opts[:id]

    %{
      id: {__MODULE__, id},
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  defp name({name, id}), do: :"#{name}#{id}"

  def start_link(opts \\ []) do
    id = opts[:id]
    GenServer.start_link(__MODULE__, id, [{:name, name(id)} | opts])
  end

  def check(id) do
    if GenServer.call(name(id), :enabled?), do: :ok, else: :error
  end

  def count({_, _} = id), do: do_count(id)

  def count(name) do
    with {_, _} = id <- Multix.get(name), do: do_count(id)
  end

  def do_count({name, _} = id) do
    with :error <- GenServer.call(name(id), :add) do
      Multix.failure(name, id)
      :error
    end
  end

  def enable(id), do: GenServer.call(name(id), :enable)
  def disable(id), do: GenServer.call(name(id), :disable)

  def init(id) do
    {:ok, %{id: id, enabled?: true, count: 0}}
  end

  def handle_call(:disable, _from, state) do
    {:reply, :ok, %{state | enabled?: false}}
  end

  def handle_call(:enable, _from, state) do
    {:reply, :ok, %{state | enabled?: true}}
  end

  def handle_call(:add, _from, %{id: id, enabled?: enabled?, count: count} = state) do
    if enabled? do
      {:reply, {id, count}, %{state | count: count + 1}}
    else
      {:reply, :error, state}
    end
  end

  def handle_call(:enabled?, _from, %{enabled?: enabled?} = state) do
    {:reply, enabled?, state}
  end
end
