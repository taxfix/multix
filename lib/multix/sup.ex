defmodule Multix.Sup do
  @moduledoc """
  Starts supervisor for `Multix` tracking process and his failure workers
  """

  alias Multix.FailureWorker

  use Supervisor

  @doc """
  Start `Multix` resource tracking process and workers.

  Options:

    * `name` - name of resource group (required)
    * `resources` - list of available resources
    * `on_get` - module, which implements callback for selection
    * `on_failure` - module or fun, which implements checking if resource is available
  """

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    children = [{Multix, opts}]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_worker(pid, id, args) do
    child_spec = %{id: id, start: {FailureWorker, :start_link, [args]}}
    Supervisor.start_child(pid, child_spec)
  end

  def stop_worker(pid, id) do
    with :ok <- Supervisor.terminate_child(pid, id), do: Supervisor.delete_child(pid, id)
  end
end
