defmodule SavvyFlagsWeb.FeatureLive.Index do
  use SavvyFlagsWeb, :live_view
  alias SavvyFlags.Features
  alias SavvyFlags.Projects
  alias SavvyFlags.Accounts.User
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.FeatureRevision

  import SavvyFlagsWeb.FeatureLive.Components, only: [feature_stats: 1]

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
    |> assign(:feature, %Feature{feature_revisions: [%FeatureRevision{}]})
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    feature = Features.get_feature_by_reference(reference)

    socket
    |> assign(:page_title, "Edit feature")
    |> assign(:feature, %{feature | feature_revisions: [feature.last_feature_revision]})
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
