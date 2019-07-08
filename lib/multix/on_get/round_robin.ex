defmodule Multix.OnGet.RoundRobin do
  @moduledoc """
  Implements round robin selection strategy
  """
  @behaviour Multix.OnGet

  @impl true
  def init(_resources) do
    :atomics.new(1, [])
  end

  @impl true
  def select(%{alive: []}, _data, _state), do: nil

  def select(%{alive: resources}, _data, atomics) do
    next_index = :atomics.add_get(atomics, 1, 1)
    index = rem(next_index, length(resources))
    Enum.at(resources, index)
  end
end
