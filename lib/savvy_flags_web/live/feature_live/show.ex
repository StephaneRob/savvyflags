defmodule SavvyFlagsWeb.FeatureLive.Show do
  use SavvyFlagsWeb, :live_view

  import SavvyFlagsWeb.FeatureLive.Components

  alias SavvyFlags.Accounts.User
  alias SavvyFlags.Features.FeatureValue
  alias SavvyFlags.Environments
  alias SavvyFlags.Environments.Environment
  alias SavvyFlags.Features.FeatureRule
  alias SavvyFlags.Features
  alias SavvyFlags.Features.Feature

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items><.link navigate={~p"/features"}>Features</.link></:items>
      <:items :if={!@environment}><.badge value={@feature.key} /></:items>
      <:items :if={@environment}>
        <.link :if={@environment} patch={~p"/features/#{@feature}"}>
          <.badge value={@feature.key} />
        </.link>
      </:items>
      <:items :if={@environment}>
        <span
          class=" h-3 w-3 inline-block rounded-sm"
          style={"background-color: #{@environment.color}"}
        >
        </span>
        <span class="capitalize">{@environment.name}</span>
        <.tag :if={@environment.id in @feature.environments_enabled} variant="success" class="ml-3">
          Active
        </.tag>
        <.tag
          :if={@environment.id not in @feature.environments_enabled}
          variant="neutral"
          class="ml-3"
        >
          Inactive
        </.tag>
      </:items>
      <:actions :if={@environment}>
        <form
          phx-change="toggle-feature-environment"
          phx-value-id={@environment.id}
          class="inline-block ml-auto"
        >
          <.toggle
            label="Enabled?"
            checked={@environment.id in @feature.environments_enabled}
            id={"feature_environments_#{@environment.name}"}
            name={"feature_environments_#{@environment.id}"}
          />
        </form>
      </:actions>
      <:subtitle></:subtitle>
    </.breadcrumb>

    <div class=" mb-6 -mt-2">
      <.feature_detail feature={@feature} />
    </div>

    <div class="flex-1">
      <div class="mt-4">
        <.feature_environment_detail
          :if={@environment}
          feature={@feature}
          environment={@environment}
        />
      </div>
      <div class="-mt-4">
        <.feature_environments :if={!@environment} feature={@feature} environments={@environments} />
      </div>
    </div>

    <.modal
      :if={@live_action in [:fr_new, :fr_edit]}
      id="fr-modal"
      show
      on_cancel={JS.patch(~p"/features/#{@feature}/environments/#{@environment}")}
    >
      <.live_component
        module={SavvyFlagsWeb.FeatureLive.FeatureRuleFormComponent}
        id={@feature_rule.id || :new}
        title={@page_title}
        action={@live_action}
        feature_rule={@feature_rule}
        environment={@environment}
        feature={@feature}
        patch={~p"/features/#{@feature}/environments/#{@environment}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(%{"reference" => reference}, _session, socket) do
    current_user = SavvyFlags.Repo.preload(socket.assigns.current_user, :environments)

    environment_ids =
      if current_user.role == :member do
        (current_user.environments || [])
        |> Enum.map(& &1.id)
      end

    feature =
      Features.get_feature_by_reference(reference)

    socket =
      if can?(current_user, feature) do
        environments = Environments.list_environments(feature, environment_ids)

        socket
        |> assign(:feature, feature)
        |> assign(:page_title, "Feature #{feature.key}")
        |> assign(:environments, environments)
        |> assign(:active_nav, :features)
      else
        socket
        |> put_flash(
          :error,
          "You are not authorized to access this feature. Please contact the admin"
        )
        |> redirect(to: ~p"/features")
      end

    socket
    |> assign(:current_user, current_user)
    |> ok()
  end

  @impl true
  def handle_params(params, _, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, %{"environment" => environment} = params)
       when action in [:environment, :fr_new, :fr_edit] do
    feature = socket.assigns.feature
    current_user = socket.assigns.current_user
    environment = Environments.get_environment(environment, feature)

    if can?(current_user, environment) do
      socket
      |> assign(:environment, environment)
      |> apply_sub_action(action, params)
    else
      socket
      |> put_flash(
        :error,
        "You are not authorized to access this environment. Please contact your admin"
      )
      |> redirect(to: ~p"/features/#{feature}")
    end
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, :environment, nil)
  end

  defp apply_sub_action(socket, :fr_new, _) do
    environment = socket.assigns.environment
    feature = socket.assigns.feature

    position =
      if rule = List.last(environment.feature_rules) do
        rule.position + 1
      else
        0
      end

    socket
    |> assign(:page_title, "New rule")
    |> assign(:feature_rule, %FeatureRule{
      feature_id: feature.id,
      environment_id: environment.id,
      feature_rule_conditions: [],
      position: position,
      value: %FeatureValue{type: feature.default_value.type, value: ""}
    })
  end

  defp apply_sub_action(socket, :fr_edit, %{"feature_rule" => feature_rule_reference}) do
    environment = socket.assigns.environment
    feature_rule = Enum.find(environment.feature_rules, &(&1.reference == feature_rule_reference))

    socket
    |> assign(:page_title, "Edit rule")
    |> assign(:feature_rule, feature_rule)
  end

  defp apply_sub_action(socket, _, _), do: socket

  @impl true
  def handle_event("reposition", params, socket) do
    feaure_rules = socket.assigns.environment.feature_rules
    Features.reorder_feature_rules(feaure_rules, params)

    socket
    |> refresh()
    |> noreply()
  end

  @impl true
  def handle_event("toggle-feature-environment", %{"id" => id} = params, socket) do
    feature = socket.assigns.feature
    id = String.to_integer(id)
    value = Map.get(params, "feature_environments_#{id}")

    environments_enabled =
      if value == "on" do
        (feature.environments_enabled ++ [id]) |> Enum.uniq()
      else
        Enum.reject(feature.environments_enabled, &(&1 == id))
      end

    {:ok, feature} =
      Features.update_feature(feature, %{
        environments_enabled: environments_enabled
      })

    socket
    |> assign(:feature, feature)
    |> put_flash(:info, "Environment correctly updated")
    |> noreply()
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.FeatureLive.FeatureRuleComponent, {:deleted, feature_rule}},
        socket
      ) do
    socket = refresh(socket)

    socket =
      if feature_rule.id do
        put_flash(socket, :info, "Feature Rule correctly deleted")
      else
        socket
      end

    noreply(socket)
  end

  @impl true
  def handle_info({SavvyFlagsWeb.FeatureLive.FeatureRuleFormComponent, {:saved, _}}, socket) do
    socket
    |> refresh()
    |> noreply()
  end

  defp refresh(socket) do
    socket
    |> update(:environment, fn environment,
                               %{
                                 feature: feature
                               } ->
      if environment do
        Environments.get_environment(environment.reference, feature)
      end
    end)
  end

  defp can?(%User{role: role}, %Environment{}) when role in [:admin, :owner],
    do: true

  defp can?(%User{role: :member, full_access: true}, %Environment{}), do: true

  defp can?(%User{environments: environments}, %Environment{id: id}) do
    Enum.any?(environments, &(&1.id == id))
  end

  defp can?(%User{role: role}, %Feature{}) when role in [:admin, :owner],
    do: true

  defp can?(%User{role: :member, full_access: true}, %Feature{}), do: true

  defp can?(user, feature) do
    features =
      Features.list_features_for_user(user.id)

    Enum.any?(features, &(&1.id == feature.id))
  end
end
