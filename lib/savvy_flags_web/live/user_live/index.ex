defmodule SavvyFlagsWeb.UserLive.Index do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.Environments
  alias SavvyFlags.Projects
  alias SavvyFlags.Features
  alias SavvyFlags.Accounts
  alias SavvyFlags.Accounts.User

  on_mount {SavvyFlagsWeb.UserAuth, :require_admin}

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Users</:items>
      <:actions>
        <.link patch={~p"/users/new"}>
          <.button>Invite user</.button>
        </.link>
      </:actions>
      <:subtitle>
        Active users.
      </:subtitle>
    </.breadcrumb>

    <.table id="members" rows={@streams.users}>
      <:col :let={{_, user}} label="Email">
        {user.email}
        <.badge :if={user.id == @current_user.id} value="me" />
      </:col>
      <:col :let={{_, user}} label="Full access">
        <span :if={
          user.role in [:admin, :owner] || (user.role not in [:admin, :owner] && user.full_access)
        }>
          <.check value={true} />
        </span>
        <%!-- <span :if={user.role not in [:admin, :owner] && user.full_access}>Yes</span> --%>
        <span :if={user.role not in [:admin, :owner] && !user.full_access}>
          <.check value={false} />
        </span>
      </:col>
      <:col :let={{_, user}} label="Projects">
        <span :if={user.role in [:admin, :owner]} class="font-semibold">All</span>
        <span :if={user.role not in [:admin, :owner] && user.full_access} class="font-semibold">
          All
        </span>
        <span :if={user.role not in [:admin, :owner] && !user.full_access}>
          {Enum.join(Enum.map(user.projects, & &1.name), ",")}
        </span>
        <span
          :if={user.role not in [:admin, :owner] && !user.full_access && user.projects == []}
          class="italic"
        >
          None
        </span>
      </:col>
      <:col :let={{_, user}} label="Features">
        <span :if={user.role in [:admin, :owner]}>All</span>
        <span :if={user.role not in [:admin, :owner] && user.full_access}>All</span>
        <span :if={user.role not in [:admin, :owner] && !user.full_access}>
          {length(user.features)}
        </span>
      </:col>
      <:col :let={{_, user}} label="Environments">
        <span :if={user.role in [:admin, :owner]}>All</span>
        <span :if={user.role not in [:admin, :owner] && user.full_access}>All</span>
        <span :if={user.role not in [:admin, :owner] && !user.full_access}>
          {length(user.environments)}
        </span>
      </:col>
      <:col :let={{_, user}} label="Role">
        <.tag :if={user.role == :owner} variant="success">{user.role}</.tag>
        <.tag :if={user.role == :admin} variant="warning">{user.role}</.tag>
        <.tag :if={user.role == :member}>{user.role}</.tag>
      </:col>
      <:col :let={{_, user}} label="2FA enabled?">
        <.check value={Accounts.mfa_enabled?(user)} />
      </:col>
      <:action :let={{_id, user}}>
        <.link :if={@current_user.id != user.id} patch={~p"/users/#{user}/edit"}>
          Edit
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="user-modal" show on_cancel={JS.patch(~p"/users")}>
      <.live_component
        module={SavvyFlagsWeb.UserLive.FormComponent}
        id={@user.id || :new}
        title={@page_title}
        action={@live_action}
        user={@user}
        projects={@projects}
        features={@features}
        environments={@environments}
        live_action={@live_action}
        patch={~p"/users"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> stream_configure(:users, dom_id: & &1.reference)
    |> stream(:users, Accounts.list_users([:projects, :features, :environments]))
    |> assign(:projects, Projects.list_projects())
    |> assign(:features, Features.list_features())
    |> assign(:environments, Environments.list_environments())
    |> assign(:active_nav, :users)
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New user")
    |> assign(:user, %User{projects: [], features: [], environments: []})
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    user =
      Accounts.get_user_by_reference!(reference)
      |> SavvyFlags.Repo.preload([:projects, :features, :environments])

    if user.id == socket.assigns.current_user.id do
      socket
      |> put_flash(:error, "You can't edit your own user")
      |> redirect(to: ~p"/users")
    else
      socket
      |> assign(:page_title, "Edit user")
      |> assign(:user, user)
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.UserLive.FormComponent, {:saved, user}},
        socket
      ) do
    {:noreply, stream_insert(socket, :users, user)}
  end
end
