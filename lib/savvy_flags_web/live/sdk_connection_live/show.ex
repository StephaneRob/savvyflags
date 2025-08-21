defmodule SavvyFlagsWeb.SdkConnectionLive.Show do
  use SavvyFlagsWeb, :live_view

  import SavvyFlagsWeb.SdkConnectionLive.Components
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureEvaluator
  alias SavvyFlags.SdkConnections
  alias SavvyFlags.SdkConnections.SdkConnection

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>
        <.link navigate={~p"/sdk-connections"}>SDK connections</.link>
      </:items>
      <:items><.code_label value={@sdk_connection.reference} /></:items>
    </.breadcrumb>

    <div class="-mt-10">
      <.navtabs>
        <:tabs>
          <.tablink
            name="Config"
            active={@live_action == :show}
            patch={~p"/sdk-connections/#{@sdk_connection}"}
          />
        </:tabs>
        <:tabs>
          <.tablink
            name="Sandbox"
            active={@live_action == :sandbox}
            patch={~p"/sdk-connections/#{@sdk_connection}/sandbox"}
          />
        </:tabs>
        <:tabs>
          <.tablink
            name="Metrics"
            active={@live_action == :metrics}
            patch={~p"/sdk-connections/#{@sdk_connection}/metrics"}
          />
        </:tabs>
      </.navtabs>
    </div>

    <.config :if={@live_action == :show} sdk_connection={@sdk_connection} />

    <.metrics
      :if={@live_action == :metrics}
      data={@data}
      last_24_hours={@last_24_hours}
      last_30_days={@last_30_days}
      sdk_connection={@sdk_connection}
    />

    <.sandbox
      :if={@live_action == :sandbox}
      sdk_connection={@sdk_connection}
      try_it_result={@try_it_result}
      json_valid?={@json_valid?}
      plain_rules={@plain_rules}
    />
    """
  end

  @impl true
  def mount(%{"reference" => sdk_connection_reference}, _, socket) do
    sdk_connection =
      SdkConnections.get_sdk_connection!(sdk_connection_reference)

    socket
    |> assign(sdk_connection: sdk_connection, active_nav: :sdk_connections)
    |> ok()
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      if socket.assigns.live_action == :metrics do
        socket = add_usage_data(socket)
        Process.send_after(self(), :tick, 5000)
        socket
      else
        socket
      end

    noreply(socket)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :show, _) do
    socket
  end

  defp apply_action(socket, :metrics, _) do
    if connected?(socket), do: Process.send_after(self(), :tick, 5000)

    socket
    |> add_usage_data()
  end

  defp apply_action(socket, :sandbox, _) do
    sdk_connection = socket.assigns.sdk_connection

    features =
      Features.list_features_for_projects_and_environments(
        sdk_connection.projects |> Enum.map(& &1.id),
        sdk_connection.environment_id
      )

    payload = FeatureEvaluator.build_plain_payload(sdk_connection, features, false)
    plain_rules = Jason.encode!(payload, pretty: true)

    socket
    |> assign(
      try_it_result: "{}",
      json_valid?: true,
      features: features,
      plain_rules: plain_rules
    )
    |> eval_sdk(socket.assigns.sdk_connection, %{})
  end

  defp add_usage_data(socket) do
    sdk_connection_id = socket.assigns.sdk_connection.id
    data_30_days = SdkConnections.generate_series(sdk_connection_id, 30)
    [[_, last_24_hours]] = SdkConnections.generate_series(sdk_connection_id, 1)
    last_30_days = Enum.reduce(data_30_days, 0, fn [_, count], acc -> acc + count end)

    socket
    |> assign(:data, data_30_days)
    |> assign(:last_30_days, last_30_days)
    |> assign(:last_24_hours, last_24_hours)
  end

  @impl true
  def handle_event("try-it-change", %{"attributes" => attributes}, socket) do
    sdk_connection = socket.assigns.sdk_connection

    attributes =
      String.replace(attributes, "\t\n", "")

    socket =
      case Jason.decode(attributes) do
        {:ok, attributes} ->
          eval_sdk(socket, sdk_connection, attributes)

        {:error, _} ->
          socket |> assign(:json_valid?, false)
      end

    noreply(socket)
  end

  defp eval_sdk(socket, %SdkConnection{mode: :remote_evaluated}, attributes) do
    features = socket.assigns.features
    evaluated_feature_flags = FeatureEvaluator.eval(features, attributes)

    socket
    |> assign(:json_valid?, true)
    |> assign(
      :try_it_result,
      Jason.encode!(evaluated_feature_flags, pretty: true)
    )
  end

  defp eval_sdk(socket, _, _) do
    socket
  end
end
