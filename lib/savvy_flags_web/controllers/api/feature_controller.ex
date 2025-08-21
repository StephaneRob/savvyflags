defmodule SavvyFlagsWeb.Api.FeatureController do
  use SavvyFlagsWeb, :controller
  require Logger
  alias SavvyFlags.FeatureCache
  alias SavvyFlags.SdkConnections
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureEvaluator

  plug :fetch_sdk_connection
  plug :check_sdk_connection_mode
  plug :load_features, only: [:create, :index]
  plug :emit_telemetry_event

  def index(conn, _) do
    current_sdk_connection = conn.assigns.current_sdk_connection

    rules =
      if rules = FeatureCache.get(rule_cache_key(current_sdk_connection)) do
        rules
      else
        rules =
          FeatureEvaluator.build_plain_payload(current_sdk_connection, conn.assigns.features)

        FeatureCache.put(rule_cache_key(current_sdk_connection), rules)
        rules
      end

    json(conn, %{features: rules})
  end

  def create(conn, params) do
    current_sdk_connection = conn.assigns.current_sdk_connection
    params_hash = params_hash(params)

    evaluated_feature_flags =
      if evaluated_feature_flags =
           FeatureCache.get(evaluated_cache_key(current_sdk_connection, params_hash)) do
        evaluated_feature_flags
      else
        evaluated_feature_flags =
          FeatureEvaluator.eval(conn.assigns.features, params)

        FeatureCache.put(
          evaluated_cache_key(current_sdk_connection, params_hash),
          evaluated_feature_flags
        )

        FeatureCache.push_unique(params_hash_cache_key(current_sdk_connection), params_hash)

        evaluated_feature_flags
      end

    json(conn, %{features: evaluated_feature_flags})
  end

  def stream(conn, _) do
    pubsub_topic = "sse_sdk_connection_#{conn.assigns.current_sdk_connection.reference}"
    Phoenix.PubSub.subscribe(SavvyFlags.PubSub, pubsub_topic)

    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> stream_events()
  end

  defp stream_events(conn) do
    receive do
      {:sse_event, _} ->
        case chunk(conn, "data: .\n\n") do
          {:ok, conn} ->
            stream_events(conn)

          {:error, "closed"} ->
            pubsub_topic = "sse_sdk_connection_#{conn.assigns.current_sdk_connection.reference}"
            Phoenix.PubSub.subscribe(SavvyFlags.PubSub, pubsub_topic)
            conn
        end

      _other ->
        stream_events(conn)
    end
  end

  defp fetch_sdk_connection(conn, _) do
    %{"sdk_connection" => sdk_connection_reference} = conn.params

    case SdkConnections.get_sdk_connection(sdk_connection_reference) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Not found"})
        |> halt()

      sdk_connection ->
        conn
        |> assign(:current_sdk_connection, sdk_connection)
    end
  end

  defp check_sdk_connection_mode(conn, _) do
    sdk_connection = conn.assigns.current_sdk_connection

    case {conn.method, sdk_connection.mode} do
      {"GET", :remote_evaluated} -> error(conn, :post)
      {"POST", :plain} -> error(conn, :get)
      _ -> conn
    end
  end

  defp load_features(conn, _) do
    %{current_sdk_connection: current_sdk_connection} = conn.assigns

    features =
      if features =
           FeatureCache.get(features_cache_key(current_sdk_connection)) do
        features
      else
        current_sdk_connection = SavvyFlags.Repo.preload(current_sdk_connection, :projects)

        features =
          Features.list_features_for_projects_and_environments(
            current_sdk_connection.projects |> Enum.map(& &1.id),
            current_sdk_connection.environment_id
          )

        FeatureCache.put(features_cache_key(current_sdk_connection), features)

        features
        |> Enum.each(
          &FeatureCache.push_unique(
            sdks_cache_key(&1),
            current_sdk_connection.reference
          )
        )

        features
      end

    assign(conn, :features, features)
  end

  defp error(conn, :post) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Remote evaluated SDK connection must use POST request with attributes as body"
    })
    |> halt()
  end

  defp error(conn, :get) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Plain SDK connection must use GET request to evaluate Feature flag locally"
    })
    |> halt()
  end

  defp emit_telemetry_event(conn, _) do
    :telemetry.execute([:sdk_connection, :start], %{}, %{
      sdk_connection_id: conn.assigns.current_sdk_connection.id
    })

    conn
  end

  defp params_hash(params) do
    params_keyword = params |> Enum.into([]) |> Enum.sort()
    :crypto.hash(:md5, :erlang.term_to_binary(params_keyword)) |> Base.url_encode64()
  end

  defp rule_cache_key(sdk_connection) do
    "sdk:#{sdk_connection.reference}:rules"
  end

  defp evaluated_cache_key(sdk_connection, params_hash) do
    "sdk:#{sdk_connection.reference}:#{params_hash}"
  end

  defp params_hash_cache_key(sdk_connection) do
    "sdk:#{sdk_connection.reference}:keys"
  end

  defp features_cache_key(sdk_connection) do
    "sdk:#{sdk_connection.reference}:features"
  end

  defp sdks_cache_key(feature) do
    "feature:#{feature.reference}:sdks"
  end
end
