defmodule SavvyFlagsWeb.SdkConnectionLive.Index do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.Projects
  alias SavvyFlags.Environments
  alias SavvyFlags.SdkConnections
  alias SavvyFlags.SdkConnections.SdkConnection

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>SDK connections</:items>
      <:actions>
        <.link patch={~p"/sdk-connections/new"}>
          <.button>New SDK connection</.button>
        </.link>
      </:actions>
      <:subtitle>
        List of SDK connections.
      </:subtitle>
    </.breadcrumb>

    <.table
      id="sdk_connections"
      rows={@streams.sdk_connections}
      row_click={
        fn {_, sdk_connection} ->
          JS.navigate(~p"/sdk-connections/#{sdk_connection}")
        end
      }
    >
      <:col :let={{_, sdk_connection}} label="Identifier">
        <.code_label value={sdk_connection.reference} />
      </:col>
      <:col :let={{_, sdk_connection}} label="Mode">
        {SavvyFlags.SdkConnections.SdkConnection.mode(sdk_connection.mode)}
      </:col>
      <:col :let={{_, sdk_connection}} label="Projects">
        {Enum.map(sdk_connection.projects, & &1.name) |> Enum.join(", ")}
      </:col>
      <:col :let={{_, sdk_connection}} label="Environments">
        {sdk_connection.environment.name}
        <span
          class="ml-3 h-4 w-4 inline-block rounded-sm"
          style={"background-color: #{sdk_connection.environment.color}"}
        >
        </span>
      </:col>
      <:action :let={{_id, sdk_connection}}>
        <.link patch={~p"/sdk-connections/#{sdk_connection}/edit"}>
          Edit
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="sdk-connection-modal"
      show
      on_cancel={JS.patch(~p"/sdk-connections")}
    >
      <.live_component
        module={SavvyFlagsWeb.SdkConnection.FormComponent}
        id={@sdk_connection.id || :new}
        title={@page_title}
        action={@live_action}
        sdk_connection={@sdk_connection}
        projects={@projects}
        environments={@environments}
        live_action={@live_action}
        patch={~p"/sdk-connections"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    sdk_connections = SdkConnections.list_sdk_connections([:projects, :environment])
    projects = Projects.list_projects()
    environments = Environments.list_environments()

    socket =
      socket
      |> stream_configure(:sdk_connection, dom_id: & &1.reference)
      |> stream(:sdk_connections, sdk_connections)
      |> assign(:projects, projects)
      |> assign(:environments, environments)
      |> assign(:active_nav, :sdk_connections)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    socket
    |> assign(:page_title, "Edit SDK connection")
    |> assign(
      :sdk_connection,
      SdkConnections.get_sdk_connection!(reference)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New SDK connection")
    |> assign(:sdk_connection, %SdkConnection{projects: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing SDK connections")
    |> assign(:sdk_connection, nil)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.SdkConnection.FormComponent, {:saved, sdk_connection}},
        socket
      ) do
    sdk_connection = SavvyFlags.Repo.preload(sdk_connection, [:environment, :projects])
    {:noreply, stream_insert(socket, :sdk_connections, sdk_connection)}
  end
end
