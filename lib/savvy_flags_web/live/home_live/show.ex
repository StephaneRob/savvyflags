defmodule SavvyFlagsWeb.HomeLive.Show do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.SdkConnections
  alias SavvyFlags.Projects
  alias SavvyFlags.Features

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_nav, :home)
      |> redirect(to: ~p"/features")

    {:ok, socket}
  end

  @impl true
  def handle_params(_, _, socket) do
    socket
    |> assign(:page_title, page_title())
    |> assign(
      projects: Projects.list_projects(),
      features: Features.list_features(),
      sdk_connections: SdkConnections.list_sdk_connections()
    )
    |> noreply()
  end

  defp page_title, do: "Home"
end
