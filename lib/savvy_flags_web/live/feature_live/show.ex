defmodule SavvyFlagsWeb.FeatureLive.Show do
  use SavvyFlagsWeb, :live_view

  import SavvyFlagsWeb.FeatureLive.Components

  alias SavvyFlags.Accounts.User
  alias SavvyFlags.Features.FeatureValue
  alias SavvyFlags.Environments
  alias SavvyFlags.Environments.Environment
  alias SavvyFlags.Features.Rule
  alias SavvyFlags.Features
  alias SavvyFlags.Features.Revisions
  alias SavvyFlags.Features.Feature

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

        assign(socket,
          page_title: "Feature #{feature.key}",
          feature: feature,
          publish_modal: false,
          environments: environments
        )
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
    environment = Environments.get_environment(environment, feature.last_revision)

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
      if rule = List.last(environment.rules) do
        rule.position + 1
      else
        0
      end

    assign(
      socket,
      page_title: "New rule",
      rule: %Rule{
        revision_id: feature.last_revision.id,
        environment_id: environment.id,
        conditions: [],
        position: position,
        value: %FeatureValue{type: feature.last_revision.value.type, value: ""}
      }
    )
  end

  defp apply_sub_action(socket, :fr_edit, %{"rule" => rule_reference}) do
    environment = socket.assigns.environment
    rule = Enum.find(environment.rules, &(&1.reference == rule_reference))
    assign(socket, page_title: "Edit rule", rule: rule)
  end

  defp apply_sub_action(socket, _, _), do: socket

  @impl true
  def handle_event("reposition", params, socket) do
    rules = socket.assigns.environment.rules
    Features.reorder_rules(rules, params)
    refresh(socket, "Rules correctly updated!")
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
  def handle_event("rollback", %{"revision-number" => revision_number}, socket) do
    feature = socket.assigns.feature

    revision =
      Enum.find(
        feature.revisions,
        &(&1.revision_number == String.to_integer(revision_number))
      )

    case Revisions.rollback_to(revision) do
      {:ok, _} ->
        refresh(socket, "Feature revision rolled back to v#{revision.revision_number}")

      {:error, _} ->
        socket
        |> put_flash(:error, "Error while rolling back the feature revision")
        |> noreply()
    end
  end

  @impl true
  def handle_event("publish-revision", _params, socket) do
    feature = socket.assigns.feature

    case Revisions.publish_revision(feature.last_revision) do
      {:ok, _} ->
        refresh(socket, "Feature revision published")

      {:error, _} ->
        socket
        |> put_flash(:error, "Error while publishing the feature revision")
        |> noreply()
    end
  end

  @impl true
  def handle_event("discard-revision", _params, socket) do
    feature = socket.assigns.feature

    case Revisions.discard_revision(feature.last_revision) do
      {:ok, _} ->
        refresh(socket, "Feature revision discarded")

      {:error, _} ->
        socket
        |> put_flash(:error, "Error while discarding the feature revision")
        |> noreply()
    end
  end

  @impl true
  def handle_event("delete-rule", %{"reference" => reference}, socket) do
    rule = Enum.find(socket.assigns.environment.rules, &(&1.reference == reference))
    feature = socket.assigns.feature
    current_user = socket.assigns.current_user

    case Features.Revisions.delete_rule_with_revision(
           rule,
           feature,
           current_user
         ) do
      {:ok, _} ->
        refresh(socket, "Feature rule deleted")

      {:error, _} ->
        socket
        |> put_flash(:error, "Error while deleting the feature rule")
        |> noreply()
    end
  end

  @impl true
  def handle_info({SavvyFlagsWeb.FeatureLive.RuleFormComponent, {:saved, _}}, socket) do
    refresh(socket)
  end

  defp refresh(socket, message \\ nil) do
    socket
    |> update(:feature, fn feature, _ -> Features.get_feature_by_reference(feature.reference) end)
    |> update(:environment, fn environment, %{feature: feature} ->
      if environment do
        Environments.get_environment(environment.reference, feature.last_revision)
      end
    end)
    |> then(&if message, do: put_flash(&1, :info, message), else: &1)
    |> noreply()
  end

  # FIXME: split in authorization module
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
    features = Features.list_features_for_user(user.id)
    Enum.any?(features, &(&1.id == feature.id))
  end
end
