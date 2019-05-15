defmodule Server.Sup do
  @moduledoc """
  Example implementation for `Multix`.
  """

  alias Multix.OnGet

  use Supervisor

  @doc """
  Start supervisor
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    ids = for id <- 1..4, do: {name, id}
    children = for id <- ids, do: {Server, Keyword.put(opts, :id, id)}

    children = [multix(name, ids) | children]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp multix(name, ids) do
    {Multix.Sup, [name: name, resources: ids, on_get: OnGet.Random, on_failure: Server]}
  end
end
