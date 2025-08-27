defmodule SavvyFlags.SdkConnections.SdkConnectionStats do
  use GenServer
  require Logger

  alias SavvyFlags.Features
  alias SavvyFlags.SdkConnections

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_info({:EXIT, _, reason}, state) do
    Logger.info("Exiting #{__MODULE__}...")
    {:stop, reason, state}
  end

  def handle_cast({:stats, %{sdk_connection_id: sdk_connection_id, features: features}}, state) do
    SdkConnections.incr_requests(sdk_connection_id)
    Features.touch(features)
    {:noreply, state}
  end

  def handle_cast({:stats, _}, state) do
    {:noreply, state}
  end

  def update_stats(meta) do
    GenServer.cast(__MODULE__, {:stats, meta})
  end
end
