defmodule SavvyFlags.Features do
  import Ecto.Query
  alias SavvyFlags.Accounts
  alias SavvyFlags.Features.FeatureRuleCondition
  alias SavvyFlags.Repo
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.FeatureRule

  def get_feature!(id), do: Repo.get(Feature, id)

  def get_feature_by_reference!(reference, preloads \\ []) do
    Repo.get_by!(Feature, reference: reference)
    |> Repo.preload(preloads)
  end

  def list_features(%Accounts.User{role: :member, full_access: false} = user, filters) do
    list_features_for_user(user.id, filters)
  end

  def list_features(%Accounts.User{}, filters) do
    list_features(filters)
  end

  def list_features(filters \\ %{}) do
    filters
    |> list_features_query()
    |> preload(:project)
    |> Repo.all()
  end

  defp list_features_query(filters) do
    query =
      from f in Feature,
        order_by: [desc: f.inserted_at],
        join: p in assoc(f, :project)

    where(query, [f, p], ^filters(filters))
  end

  def list_features_for_user(user_id, filters \\ %{}) do
    user_id
    |> list_features_for_user_query(filters)
    |> preload(:project)
    |> Repo.all()
  end

  defp list_features_for_user_query(user_id, filters) do
    query =
      from f in Feature,
        left_join: u in assoc(f, :users),
        join: p in assoc(f, :project),
        left_join: up in assoc(p, :users),
        order_by: [desc: f.inserted_at],
        where: u.id == ^user_id or up.id == ^user_id

    where(query, [f], ^filters(filters))
  end

  defp filters(filters) do
    dynamic = Enum.reduce(filters, dynamic(true), &apply_filter/2)

    if Map.get(filters, "archived") do
      dynamic
    else
      dynamic([f], ^dynamic and is_nil(f.archived_at))
    end
  end

  defp apply_filter({"project_id", value}, dynamic) when value != "" do
    dynamic([f], ^dynamic and f.project_id == ^value)
  end

  defp apply_filter({"key", value}, dynamic) when value != "" do
    value = "%#{value}%"
    dynamic([f], ^dynamic and ilike(f.key, ^value))
  end

  defp apply_filter({"project_reference", value}, dynamic) when value != "" do
    dynamic([f, p], ^dynamic and p.reference == ^value)
  end

  defp apply_filter({"archived", "on"}, dynamic) do
    dynamic([f], ^dynamic and not is_nil(f.archived_at))
  end

  defp apply_filter({"archived", "off"}, dynamic) do
    dynamic([f], ^dynamic and is_nil(f.archived_at))
  end

  defp apply_filter({"value_type", value}, dynamic) when value != "" do
    dynamic([f], ^dynamic and fragment("default_value ->'type' = ?", ^value))
  end

  defp apply_filter(_, dynamic), do: dynamic

  def list_features_for_projects_and_environments(project_ids, environment_id) do
    feature_rule_query =
      from fr in FeatureRule,
        where: fr.environment_id == ^environment_id and not fr.scheduled,
        order_by: [asc: :position],
        preload: [feature_rule_conditions: :attribute]

    q =
      from f in Feature,
        where: f.project_id in ^project_ids,
        where: is_nil(f.archived_at),
        where: ^environment_id in f.environments_enabled,
        preload: [feature_rules: ^feature_rule_query]

    Repo.all(q)
  end

  def get_feature_by_reference(reference) do
    query =
      from f in Feature,
        where: f.reference == ^reference,
        preload: [:environments, feature_rules: [feature_rule_conditions: :attribute]]

    Repo.one!(query)
  end

  def create_feature(attrs \\ %{}) do
    %Feature{}
    |> Feature.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_feature(feature) do
    Repo.delete(feature)
  end

  def touch(feature_ids) when is_list(feature_ids) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    query =
      from f in Feature,
        where:
          f.id in ^feature_ids and (f.last_used_at > ago(15, "minute") or is_nil(f.last_used_at)),
        update: [set: [last_used_at: ^now]]

    Repo.update_all(query, [])
  end

  def touch(feature) do
    feature
    |> Ecto.Changeset.change(%{last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  def update_feature(feature, attrs \\ %{}) do
    response =
      feature
      |> Feature.changeset(attrs)
      |> Repo.update()

    case response do
      {:ok, feature} ->
        SavvyFlags.FeatureCache.reset(feature)
        response

      error ->
        error
    end
  end

  def change_feature(feature, attrs \\ %{}) do
    Feature.changeset(feature, attrs)
  end

  def archive_feature(feature) do
    feature
    |> Ecto.Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  def get_feature_rule_by_reference!(reference) do
    FeatureRule
    |> Repo.get_by!(reference: reference)
    |> Repo.preload(:feature_rule_conditions)
  end

  def get_feature_rule_condition_by_reference!(value) when value in ["", nil] do
    nil
  end

  def get_feature_rule_condition_by_reference!(reference) do
    FeatureRuleCondition
    |> Repo.get_by!(reference: reference)
  end

  def create_feature_rule(attrs \\ %{}) do
    %FeatureRule{}
    |> Repo.preload(:feature_rule_conditions)
    |> FeatureRule.changeset(attrs)
    |> Repo.insert()
  end

  def update_feature_rule(feature_rule, attrs \\ %{}) do
    response =
      feature_rule
      |> Repo.preload([:feature_rule_conditions, :feature])
      |> FeatureRule.changeset(attrs)
      |> Repo.update()

    case response do
      {:ok, feature_rule} ->
        spawn(fn ->
          SavvyFlags.FeatureCache.reset(feature_rule.feature)
        end)

        response

      error ->
        error
    end
  end

  def change_feature_rule(feature_rule, attrs \\ %{}) do
    FeatureRule.changeset(feature_rule, attrs)
  end

  def delete_feature_rule(feature_rule) do
    Repo.delete(feature_rule)
  end

  def reorder_feature_rules(features_rules, %{"old" => old, "new" => new, "id" => id})
      when old < new do
    moved_feature_rule = Enum.find(features_rules, &(&1.id == id || "#{&1.id}" == id))
    lower_items = Enum.filter(features_rules, &(&1.position > old && &1.position <= new))

    Repo.transaction(fn ->
      update_feature_rule(moved_feature_rule, %{position: new})

      Enum.each(lower_items, fn i ->
        position = i.position - 1
        update_feature_rule(i, %{position: position})
      end)
    end)
  end

  def reorder_feature_rules(features_rules, %{"old" => old, "new" => new, "id" => id})
      when old > new do
    moved_feature_rule = Enum.find(features_rules, &(&1.id == id || "#{&1.id}" == id))
    lower_items = Enum.filter(features_rules, &(&1.position < old && &1.position >= new))

    Repo.transaction(fn ->
      update_feature_rule(moved_feature_rule, %{position: new})

      Enum.each(lower_items, fn i ->
        position = i.position + 1
        update_feature_rule(i, %{position: position})
      end)
    end)
  end

  def reorder_feature_rules(_, _) do
  end

  def enable_feature_rules! do
    now = DateTime.utc_now()

    query =
      from fr in FeatureRule,
        where: fr.scheduled_at < ^now and fr.scheduled

    Repo.update_all(query, set: [scheduled: false, scheduled_at: nil, activated_at: now])
  end
end
