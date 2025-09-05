defmodule SavvyFlagsWeb.SdkConnectionLive.Show do
  use SavvyFlagsWeb, :live_view

  import SavvyFlagsWeb.SdkConnectionLive.Components
  alias SavvyFlags.Attributes
  alias SavvyFlags.Features
  alias SavvyFlags.Features.Evaluator
  alias SavvyFlags.SdkConnections
  alias SavvyFlags.SdkConnections.SdkConnection

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>
        <.link navigate={~p"/sdk-connections"}>SDK connections</.link>
      </:items>
      <:items><.badge value={@sdk_connection.reference} /></:items>
    </.breadcrumb>

    <div class="-mt-4">
      <.navtabs>
        <:tabs>
          <.tablink
            name="Config"
            active={@live_action == :show}
            patch={~p"/sdk-connections/#{@sdk_connection}"}
          />
        </:tabs>
        <:tabs :if={@sdk_connection.mode == :remote_evaluated}>
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

    <.config :if={@live_action == :show} sdk_connection={@sdk_connection} plain_rules={@plain_rules} />

    <.metrics
      :if={@live_action == :metrics}
      data={@data}
      last_24_hours={@last_24_hours}
      last_30_days={@last_30_days}
    />

    <.sandbox
      :if={@live_action == :sandbox}
      sdk_connection={@sdk_connection}
      attributes={@attributes}
      evaluation_result={@evaluation_result}
      json_valid?={@json_valid?}
      json={@json}
    />
    """
  end

  @impl true
  def mount(%{"reference" => sdk_connection_reference}, _, socket) do
    sdk_connection =
      SdkConnections.get_sdk_connection!(sdk_connection_reference)

    features =
      Features.list_features_for_projects_and_environments(
        sdk_connection.projects |> Enum.map(& &1.id),
        sdk_connection.environment_id
      )

    payload = Evaluator.build_plain_payload(sdk_connection, features, false)
    plain_rules = Jason.encode!(payload, pretty: true)

    socket
    |> assign(
      page_title: "SDK connection #{sdk_connection.reference}",
      features: features,
      plain_rules: plain_rules,
      sdk_connection: sdk_connection,
      attributes: Attributes.list_attributes()
    )
    |> ok()
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      if socket.assigns.live_action == :metrics do
        Process.send_after(self(), :tick, 5000)
        add_usage_data(socket)
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
    add_usage_data(socket)
  end

  defp apply_action(socket, :sandbox, _) do
    socket
    |> assign(
      json: "{\n  \"email\":\"example@gmail.com\"\n}",
      evaluation_result: "{}",
      json_valid?: true
    )
    |> eval_sdk(socket.assigns.sdk_connection, %{})
  end

  defp add_usage_data(socket) do
    sdk_connection = socket.assigns.sdk_connection
    data_30_days = SdkConnections.generate_series(sdk_connection.id, 30)
    [_, global_count] = data_30_days
    last_24_hours = List.last(global_count)
    last_30_days = Enum.sum(global_count)

    assign(socket,
      data: data_30_days,
      last_30_days: last_30_days,
      last_24_hours: last_24_hours
    )
  end

  @impl true
  def handle_event("evaluate", %{"payload" => payload}, socket) do
    sdk_connection = socket.assigns.sdk_connection

    socket =
      case Jason.decode(payload) do
        {:ok, decoded_payload} ->
          socket
          |> assign(:json, payload)
          |> eval_sdk(sdk_connection, decoded_payload)

        {:error, _} ->
          assign(socket, :json_valid?, false)
      end

    noreply(socket)
  end

  defp eval_sdk(socket, %SdkConnection{mode: :remote_evaluated}, payload) do
    features = socket.assigns.features
    evaluated_feature_flags = Evaluator.eval(features, payload)
    evaluation_result = Jason.encode!(evaluated_feature_flags, pretty: true)
    assign(socket, json_valid?: true, evaluation_result: evaluation_result)
  end

  defp eval_sdk(socket, _, _) do
    socket
  end
end
