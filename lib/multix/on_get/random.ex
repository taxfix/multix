defmodule Multix.OnGet.Random do
  @moduledoc """
  Implements quickest pseudo random selection strategy
  """
  @behaviour Multix.OnGet

  @impl true
  def init(_resources) do
    nil
  end

  @impl true
  def select(resources, _data, _state) do
    {_, _, micro_secs} = :os.timestamp()
    index = rem(micro_secs, length(resources))
    Enum.at(resources, index)
  end
end
