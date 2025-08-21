defmodule SavvyFlags.SdkConnections.SdkConnectionStats do
  use GenServer
  require Logger

  alias SavvyFlags.SdkConnections

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    setup()
    {:ok, %{}}
  end

  def handle_info({:EXIT, _, reason}, state) do
    Logger.info("Exiting #{__MODULE__}...")
    {:stop, reason, state}
  end

  def handle_cast({:enqueue, meta}, state) do
    %{sdk_connection_id: sdk_connection_id} = meta
    SdkConnections.incr_requests(sdk_connection_id)
    {:noreply, state}
  end

  def setup do
    handlers = %{
      [:sdk_connection, :start] => &__MODULE__.sdk_connection_start/4
    }

    for {key, fun} <- handlers do
      :telemetry.attach({__MODULE__, key}, key, fun, :ok)
    end
  end

  def sdk_connection_start(_, _, meta, _) do
    GenServer.cast(__MODULE__, {:enqueue, meta})
  end
end
