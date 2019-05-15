defmodule Multix do
  @moduledoc """
  Multix allows to manage availiability of resources.
  """

  @type resource :: any()

  alias Multix.OnGet

  use GenServer

  @available_resources :available_resources
  @all_resources :all_resources

  @doc """
  Get available resource.
  """
  def get(name, data \\ nil) do
    case :ets.lookup(name, @available_resources) do
      [{@available_resources, [], _}] ->
        nil

      [{@available_resources, resources, %{mod: module, state: state}}] ->
        OnGet.select(module, resources, data, state)
    end
  catch
    _, _ -> :error
  end

  @doc """
  Notify about workers resource.
  """
  def failure(name, resource) do
    GenServer.call(name, {:failure, resource})
  end

  @doc false
  def restore(name, resource) do
    GenServer.call(name, {:restore, resource})
  end

  defstruct name: nil,
            on_get: nil,
            on_failure: nil,
            available_resources: [],
            resources: [],
            workers: %{}

  @doc """
  Start multix process.
  """
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc false
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    resources = Keyword.fetch!(opts, :resources)
    on_get = Keyword.get(opts, :on_get, OnGet.Random)
    on_failure = Keyword.get(opts, :on_failure, nil)

    Process.flag(:trap_exit, true)
    get_spec = %{mod: on_get, state: OnGet.init(on_get, resources)}

    :ets.new(name, [:named_table, :public, read_concurrency: true])
    :ets.insert(name, {@all_resources, resources, nil})
    :ets.insert(name, {@available_resources, resources, get_spec})

    state = %__MODULE__{
      name: name,
      on_get: on_get,
      on_failure: on_failure,
      resources: resources,
      available_resources: resources
    }

    {:ok, state}
  end

  def handle_call({:failure, resource}, _from, state) do
    {reply, new_state} = handle_failure(resource, state)
    {:reply, reply, new_state}
  end

  def handle_call({:restore, resource}, _from, state) do
    {:reply, :ok, state, {:continue, {:restore, resource}}}
  end

  def handle_continue({:restore, resource}, state) do
    {:noreply, handle_restore(resource, state)}
  end

  defp handle_failure(resource, state) do
    %__MODULE__{name: name, available_resources: available_resources} = state

    if resource in available_resources do
      new_available_resources = available_resources -- [resource]
      :ets.update_element(name, @available_resources, {2, new_available_resources})
      state = start_worker(state, resource)
      {:ok, %__MODULE__{state | available_resources: new_available_resources}}
    else
      {:already, state}
    end
  end

  defp start_worker(%{name: name, workers: workers, on_failure: on_failure} = state, resource) do
    id = {name, resource}
    args = [name, resource, on_failure]
    {:ok, worker} = Multix.Sup.start_worker(get_supervisor(), id, args)
    %{state | workers: Map.put(workers, resource, worker)}
  end

  defp get_supervisor() do
    [supervisor | _] = Process.get(:"$ancestors")
    supervisor
  end

  defp handle_restore(resource, state) do
    %__MODULE__{name: name, available_resources: available_resources} = state

    new_available_resources = [resource | available_resources]
    :ets.update_element(name, @available_resources, {2, new_available_resources})

    state = stop_worker(state, resource)
    %__MODULE__{state | available_resources: new_available_resources}
  end

  defp stop_worker(%{name: name, workers: workers} = state, resource) do
    id = {name, resource}
    :ok = Multix.Sup.stop_worker(get_supervisor(), id)
    %{state | workers: Map.delete(workers, resource)}
  end
end
