defmodule SavvyFlags.Features do
  import Ecto.Query
  alias SavvyFlags.Features.FeatureStat
  alias SavvyFlags.Accounts
  alias SavvyFlags.Configurations
  alias SavvyFlags.Repo
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.FeatureRevision
  alias SavvyFlags.Features.FeatureStat
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

  def default_feature_preloads do
    [
      feature_revisions: :feature_rules,
      feature_stats: :environment,
      last_feature_revision: last_feature_revision_query()
    ]
  end

  defp list_features_query(filters) do
    query =
      from f in Feature,
        order_by: [desc: f.inserted_at],
        join: p in assoc(f, :project),
        join: fr in assoc(f, :feature_revisions),
        join: ir in assoc(f, :initial_feature_revision),
        preload: ^default_feature_preloads()

    where(query, [f, p, ir], ^filters(filters))
  end

  defp last_feature_revision_query do
    from fr in FeatureRevision,
      order_by: [desc: fr.revision_number],
      limit: 1
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
        where: u.id == ^user_id or up.id == ^user_id,
        preload: ^default_feature_preloads()

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
    dynamic([f, p, ir], ^dynamic and fragment("? ->'type' = ?", ir.value, ^value))
  end

  defp apply_filter(_, dynamic), do: dynamic

  def list_features_for_projects_and_environments(project_ids, environment_id) do
    feature_rule_query =
      from fr in FeatureRule,
        where: fr.environment_id == ^environment_id and not fr.scheduled,
        order_by: [asc: :position]

    q =
      from f in Feature,
        where: f.project_id in ^project_ids,
        where: is_nil(f.archived_at),
        where: ^environment_id in f.environments_enabled,
        join: cr in assoc(f, :current_feature_revision),
        preload: [current_feature_revision: [feature_rules: ^feature_rule_query]]

    Repo.all(q)
  end

  def get_feature_by_reference(reference) do
    query =
      from f in Feature,
        where: f.reference == ^reference,
        preload: [
          feature_revisions: :feature_rules,
          feature_stats: :environment,
          last_feature_revision: ^last_feature_revision_query()
        ]

    Repo.one!(query)
  end

  def create_feature(attrs \\ %{}) do
    %Feature{}
    |> Repo.preload(:feature_revisions)
    |> Feature.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_feature(feature) do
    Repo.delete(feature)
  end

  def touch(feature_ids, environment_id) when is_list(feature_ids) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    feature_stats =
      Enum.map(
        feature_ids,
        &%{
          feature_id: &1,
          environment_id: environment_id,
          first_used_at: now,
          last_used_at: now,
          inserted_at: now,
          updated_at: now
        }
      )

    Repo.insert_all(
      FeatureStat,
      feature_stats,
      conflict_target: [:feature_id, :environment_id],
      on_conflict: {:replace, [:last_used_at, :updated_at]}
    )
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

  def stale?(feature) do
    threshold = Configurations.stale_threshold()

    last_used_at =
      if feature.feature_stats != [] do
        List.first(feature.feature_stats).last_used_at
      end

    case last_used_at do
      nil -> false
      last_used_at -> DateTime.diff(DateTime.utc_now(), last_used_at, :day) > threshold
    end
  end

  def get_feature_rule_by_reference!(reference) do
    FeatureRule
    |> Repo.get_by!(reference: reference)
  end

  def create_feature_rule(attrs \\ %{}) do
    %FeatureRule{}
    |> FeatureRule.changeset(attrs)
    |> Repo.insert()
  end

  # FIXME handle Cache reset
  def update_feature_rule(feature_rule, attrs \\ %{}) do
    feature_rule
    |> Repo.preload([:feature_revision])
    |> FeatureRule.changeset(attrs)
    |> Repo.update()
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
