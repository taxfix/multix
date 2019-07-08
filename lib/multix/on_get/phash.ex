defmodule Multix.OnGet.Phash do
  @moduledoc """
  Implements simple hashing selection strategy, based on provided data.
  """
  @behaviour Multix.OnGet

  @impl true
  def init(_resources) do
    nil
  end

  @impl true
  def select(%{alive: []}, _data, _state), do: nil

  def select(%{alive: resources}, data, _state) do
    index = :erlang.phash2(data, length(resources))
    Enum.at(resources, index)
  end
end
