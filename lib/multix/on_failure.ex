defmodule Multix.OnFailure do
  @moduledoc """
  Behaviour for failure strategy.
  """
  require Logger

  @callback check(Multix.resource()) :: :ok | :error

  def check(module_or_fun, resource) do
    cond do
      is_atom(module_or_fun) -> module_or_fun.check(resource)
      is_function(module_or_fun, 1) -> module_or_fun.(resource)
    end
  catch
    kind, error ->
      Logger.warn(
        "callback #{inspect(module_or_fun)} resource #{inspect(resource)} catched with " <>
          inspect({kind, error, __STACKTRACE__})
      )

      :error
  else
    :error ->
      :error

    :ok ->
      :ok

    unknown ->
      Logger.warn(
        "callback #{inspect(module_or_fun)} resource #{inspect(resource)} returned unknown error " <>
          inspect(unknown)
      )

      :error
  end
end
