defmodule SavvyFlagsWeb.FeatureLive.Index do
  use SavvyFlagsWeb, :live_view
  alias SavvyFlags.Features
  alias SavvyFlags.Projects
  alias SavvyFlags.Accounts.User
  alias SavvyFlags.Features.Feature

  import SavvyFlagsWeb.FeatureLive.Components, only: [feature_stats: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Features</:items>
      <:actions>
        <.link patch={~p"/features/new"}>
          <.button>New feature</.button>
        </.link>
      </:actions>

      <:subtitle>
        Features enable you to change your app's behavior. For example, turn on/off a sales banner or change the title of your pricing page.
      </:subtitle>
    </.breadcrumb>

    <form id="features_search" class="flex items-end gap-5" phx-change="filter-features">
      <.input
        name="filter[project_id]"
        label="Project"
        prompt="All"
        options={Enum.into(@projects, [], &{:"#{&1.name}", &1.id})}
        type="select"
        value={@filter["project_id"]}
      />
      <.input
        name="filter[value_type]"
        label="Value type"
        options={SavvyFlags.Features.Feature.value_types()}
        type="select"
        prompt="All"
        value={@filter["value_type"]}
      />
      <.toggle
        name="filter[archived]"
        label="Archived?"
        checked={@filter["archived"]}
        id="filter[archived]"
      />
      <.button type="button" variant="outline" disabled={!Enum.any?(@filter)} phx-click="reset-filter">
        Reset filter
      </.button>
    </form>
    <.table
      class="mt-5"
      id="features"
      rows={@streams.features}
      row_click={
        fn
          {_id, %Feature{archived_at: nil} = feature} ->
            JS.navigate(~p"/features/#{feature}")

          {_id, _} ->
            nil
        end
      }
    >
      <:col :let={{_, feature}} label="Key">
        <.badge value={feature.key} />
        <%= if feature.archived_at do %>
          <.badge variant="warning" class="ml-3" value="Archived" size="sm" />
        <% end %>
        <br />
        <span class="text-xs font-normal text-neutral-500">{feature.description}</span>
      </:col>
      <:col :let={{_, feature}} label="Default value">
        {feature.default_value.value}
      </:col>
      <:col :let={{_, feature}} label="Value type">{feature.default_value.type}</:col>
      <:col :let={{_, feature}} label="Project">{feature.project.name}</:col>
      <:col :let={{_, feature}} label="Sdk cache">
        <.badge
          :for={sdk <- SavvyFlags.FeatureCache.get("feature:#{feature.reference}:sdks") || []}
          value={sdk}
          class="mr-1"
        />
      </:col>
      <:col :let={{_, feature}} label="Last used at">
        <.feature_stats feature={feature} />
      </:col>
      <:col :let={{_, feature}} label="Last updated at">
        <.datetime value={feature.updated_at} />
      </:col>
      <:action :let={{_id, feature}}>
        <.link :if={is_nil(feature.archived_at)} patch={~p"/features/#{feature}/edit"}>
          <.icon name="hero-pencil-square" class="w-4 h-4" />
        </.link>
      </:action>
      <:action :let={{_id, feature}}>
        <.link
          :if={is_nil(feature.archived_at)}
          data-confirm="Do you really want to archive this feature?"
          phx-click="archive"
          phx-value-feature={feature.id}
        >
          <.icon name="hero-archive-box-arrow-down" class="w-4 h-4 text-rose-500" />
        </.link>
      </:action>
    </.table>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="feature-modal"
      show
      on_cancel={JS.patch(~p"/features")}
    >
      <.live_component
        module={SavvyFlagsWeb.FeatureLive.FormComponent}
        id={:new}
        title={@page_title}
        action={@live_action}
        feature={@feature}
        projects={@projects}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    features = load_features(socket)

    socket
    |> stream_configure(:features, dom_id: & &1.reference)
    |> stream(:features, features, reset: true)
    |> assign(:projects, Projects.list_projects())
    |> assign(:filter, %{})
    |> assign(:active_nav, :features)
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New feature")
    |> assign(:feature, %Feature{})
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    socket
    |> assign(:page_title, "Edit feature")
    |> assign(:feature, Features.get_feature_by_reference(reference))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Features")
    |> assign(:feature, nil)
  end

  @impl true
  def handle_event("filter-features", %{"filter" => filter_params}, socket) do
    features = load_features(socket, filter_params)

    socket
    |> assign(:filter, filter_params)
    |> stream(:features, features, reset: true)
    |> noreply()
  end

  @impl true
  def handle_event("reset-filter", _, socket) do
    features = load_features(socket)

    socket
    |> assign(:filter, %{})
    |> stream(:features, features, reset: true)
    |> noreply()
  end

  @impl true
  def handle_event("archive", %{"feature" => id}, socket) do
    feature = Features.get_feature!(id)
    Features.archive_feature(feature)
    features = load_features(socket)

    socket
    |> stream(:features, features, reset: true)
    |> put_flash(:info, "Feature archived successfully")
    |> noreply()
  end

  defp do_load_features(
         %User{role: :member, full_access: false} = user,
         filter_params
       ) do
    Features.list_features_for_user(
      user.id,
      filter_params
    )
  end

  defp do_load_features(_, filter_params) do
    Features.list_features(filter_params)
  end

  defp load_features(%Phoenix.LiveView.Socket{} = socket, filter_params \\ %{}) do
    user = socket.assigns.current_user
    do_load_features(user, filter_params)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.FeatureLive.FormComponent, {:saved, feature}},
        socket
      ) do
    feature = SavvyFlags.Repo.preload(feature, [:project])
    {:noreply, stream_insert(socket, :features, feature)}
  end
end
