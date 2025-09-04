defmodule SavvyFlags.RulesActivator do
  use GenServer
  require Logger
  alias SavvyFlags.Features

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    schedule()
    {:ok, %{}}
  end

  def handle_info(:activate, state) do
    {count, _} = Features.enable_rules!()
    Logger.info("#{count} activated feature rule(s).")
    schedule()
    {:noreply, state}
  end

  defp schedule do
    Process.send_after(__MODULE__, :activate, :timer.minutes(1))
  end
end
