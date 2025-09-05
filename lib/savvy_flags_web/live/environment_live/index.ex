defmodule SavvyFlagsWeb.EnvironmentLive.Index do
  use SavvyFlagsWeb, :live_view
  alias SavvyFlags.Environments
  alias SavvyFlags.Environments.Environment

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Environments</:items>
      <:actions>
        <.link patch={~p"/environments/new"}>
          <.button>Add environment</.button>
        </.link>
      </:actions>
      <:subtitle>
        Manage which environments are available for your feature flags.
      </:subtitle>
    </.breadcrumb>

    <.table id="environments" rows={@streams.environments}>
      <:col :let={{_, environment}} label="Name">
        <span
          class="h-4 w-4 inline-block rounded-sm mr-2"
          style={"background-color: #{environment.color}"}
        >
        </span> <code>{environment.name}</code>
      </:col>
      <:col :let={{_, environment}} label="Description">{environment.description}</:col>
      <:action :let={{_id, environment}}>
        <.link patch={~p"/environments/#{environment}/edit"}>
          Edit
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="environment-modal"
      show
      on_cancel={JS.patch(~p"/environments")}
    >
      <.live_component
        module={SavvyFlagsWeb.EnvironmentLive.FormComponent}
        id={@environment.id || :new}
        title={@page_title}
        action={@live_action}
        environment={@environment}
        patch={~p"/environments"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    environments = Environments.list_environments()

    socket
    |> stream_configure(:environments, dom_id: & &1.reference)
    |> stream(:environments, environments)
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    socket
    |> assign(:page_title, "Edit environment")
    |> assign(:environment, Environments.get_environment_by_reference!(reference))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New environment")
    |> assign(:environment, %Environment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing environments")
    |> assign(:environment, nil)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.EnvironmentLive.FormComponent, {:saved, environment}},
        socket
      ) do
    {:noreply, stream_insert(socket, :environments, environment)}
  end
end
