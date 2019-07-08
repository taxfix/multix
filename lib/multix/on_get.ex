defmodule Multix.OnGet do
  @moduledoc """
  Behaviour for strategy, which should be used to get resource. There are 2 default strategies:

    * random - via `Multix.Get.Random`
    * round robin - via `Multix.Get.RoundRobin`

  """
  @type state :: any()
  @type data :: any()
  @type resource_info :: %{alive: [Multix.resource()], configured: [Multix.resource()]}

  @callback init([Multix.resource()]) :: state()

  @callback select(resource_info(), data(), state()) :: Multix.resource()

  def init(module, resources), do: module.init(resources)

  def select(module, resources, data, state), do: module.select(resources, data, state)
end
