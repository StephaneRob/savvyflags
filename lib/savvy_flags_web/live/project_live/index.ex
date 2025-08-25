defmodule SavvyFlagsWeb.ProjectLive.Index do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.Projects
  alias SavvyFlags.Projects.Project

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Projects</:items>
      <:actions>
        <.link patch={~p"/projects/new"}>
          <.button>Add project</.button>
        </.link>
      </:actions>
      <:subtitle>
        Group your ideas and experiments into Projects to keep things organized and easy to manage.
      </:subtitle>
    </.breadcrumb>

    <.table id="projects" rows={@streams.projects}>
      <:col :let={{_, project}} label="Name"><code>{project.name}</code></:col>
      <:col :let={{_, project}} label="Description">{project.description}</:col>
      <:action :let={{_id, project}}>
        <.link patch={~p"/projects/#{project}/edit"}>
          Edit
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="project-modal"
      show
      on_cancel={JS.patch(~p"/projects")}
    >
      <.live_component
        module={SavvyFlagsWeb.ProjectLive.FormComponent}
        id={@project.id || :new}
        title={@page_title}
        action={@live_action}
        project={@project}
        patch={~p"/projects"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    projects = Projects.list_projects()

    socket =
      socket
      |> stream_configure(:projects, dom_id: & &1.reference)
      |> stream(:projects, projects)
      |> assign(:active_nav, :projects)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    socket
    |> assign(:page_title, "Edit project")
    |> assign(:project, Projects.get_project_by_reference!(reference))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing project")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.ProjectLive.FormComponent, {:saved, project}},
        socket
      ) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
