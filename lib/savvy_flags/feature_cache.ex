defmodule SavvyFlags.FeatureCache do
  require Logger
  alias SavvyFlags.SdkConnections
  @ttl :timer.minutes(10)

  def get(key) do
    case Cachex.get(__MODULE__, key) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  def put(key, value) do
    Cachex.put(__MODULE__, key, value, ttl: @ttl)
  end

  def del(key) do
    Cachex.del(__MODULE__, key)
  end

  def push(key, value) do
    old_value = get(key) || []
    put(key, [value | old_value])
  end

  def push_unique(key, value) do
    old_value = get(key) || []
    new_value = Enum.uniq([value | old_value])
    put(key, new_value)
  end

  def reset(feature) do
    sdk_connections = SdkConnections.list_sdk_connections_for_feature(feature)

    Logger.info(
      "Resetting feature cache for #{feature.reference} on #{inspect(Enum.map(sdk_connections, & &1.reference))} SDK connections"
    )

    Enum.each(sdk_connections, fn sdk_connection ->
      keys = get("sdk:#{sdk_connection.reference}:keys") || []

      Enum.each(keys || [], fn key ->
        del("sdk:#{sdk_connection.reference}:#{key}")
      end)

      del("sdk:#{sdk_connection.reference}:keys")
      del("sdk:#{sdk_connection.reference}:features")
      del("sdk:#{sdk_connection.reference}:rules")
    end)

    del("feature:#{feature.reference}:sdks")

    Enum.each(sdk_connections, fn sdk_connection ->
      Phoenix.PubSub.broadcast(
        SavvyFlags.PubSub,
        "sse_sdk_connection_#{sdk_connection.reference}",
        {:sse_event, ""}
      )
    end)
  end
end
