defmodule Multix.FailureWorker do
  @moduledoc false
  alias Multix.OnFailure

  require Logger
  use GenServer

  @min_backoff 100
  @max_backoff 15_000

  defstruct [:name, :resource, :on_failure, :backoff, :ref]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def init([name, resource, on_failure]) do
    state = %__MODULE__{
      name: name,
      resource: resource,
      on_failure: on_failure,
      backoff: @min_backoff
    }

    {:ok, state, {:continue, :check}}
  end

  def handle_continue(:check, state) do
    {:noreply, check_health(state)}
  end

  def handle_info(:check, state) do
    {:noreply, check_health(state)}
  end

  defp check_health(%__MODULE__{name: name, resource: resource, on_failure: on_failure} = state) do
    case OnFailure.check(on_failure, resource) do
      :ok -> Multix.restore(name, resource)
      :error -> apply_backoff(state)
    end
  end

  defp apply_backoff(%__MODULE__{backoff: last_backoff} = state) do
    backoff = rand_increment(last_backoff, @max_backoff)
    %__MODULE__{state | ref: Process.send_after(self(), :check, backoff), backoff: backoff}
  end

  # Increment an integer exponentially with randomness or jitter.
  # As recommended in (via Fred Herbert):
  # Sally Floyd and Van Jacobson, The Synchronization of Periodic Routing Messages,
  # April 1994 IEEE/ACM Transactions on Networking.
  # http://ee.lbl.gov/papers/sync_94.pdf
  import Bitwise, only: [bsl: 2]

  defp rand_increment(n) do
    width = bsl(n, 1)
    n + :rand.uniform(width + 1) - 1
  end

  defp rand_increment(n, max) do
    max_min_delay = div(max, 3)

    cond do
      max_min_delay == 0 -> :rand.uniform(max)
      n > max_min_delay -> rand_increment(max_min_delay)
      true -> rand_increment(n)
    end
  end
end
