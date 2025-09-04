defmodule SavvyFlags.Features.FeatureRevisions do
  @dialyzer {:nowarn_function,
             start_revision: 3, publish_revision: 1, discard_revision: 1, rollback_to: 1}

  import Ecto.Query, warn: false

  alias SavvyFlags.Utils
  alias Ecto.Multi
  alias SavvyFlags.Repo
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureRule
  alias SavvyFlags.Features.FeatureRevision

  def rollback_to(feature_revision) do
    Multi.new()
    |> Multi.delete_all(
      :unpublish_others,
      from(fr in FeatureRevision,
        where:
          fr.feature_id == ^feature_revision.feature_id and
            fr.revision_number > ^feature_revision.revision_number
      ),
      set: [status: :unpublished]
    )
    |> Multi.update(
      :publish_revision,
      FeatureRevision.changeset(feature_revision, %{status: :published})
    )
    |> Repo.transact()
  end

  def discard_revision(feature_revision) do
    Multi.new()
    |> Multi.delete(:feature_revision, feature_revision)
    |> Repo.transact()
  end

  def publish_revision(feature_revision) do
    Multi.new()
    |> Multi.update_all(
      :unpublish_others,
      from(fr in FeatureRevision,
        where: fr.feature_id == ^feature_revision.feature_id and fr.id != ^feature_revision.id
      ),
      set: [status: :unpublished]
    )
    |> Multi.update(
      :publish_revision,
      FeatureRevision.changeset(feature_revision, %{status: :published})
    )
    |> Repo.transact()
  end

  def update_feature_revision(feature, user, attrs) do
    feature
    |> start_revision(user, attrs)
    |> Multi.update(:feature_revision_updated, fn %{
                                                    feature_revision: feature_revision,
                                                    feature: feature
                                                  } ->
      feature_revisions_params = Utils.get_value(attrs, :feature_revisions, %{})
      attrs = Utils.get_value(feature_revisions_params, :"0", %{})

      if feature_revision do
        Features.change_feature_revision(feature_revision, attrs)
      else
        Features.change_feature_revision(feature.last_feature_revision, attrs)
      end
    end)
    |> Repo.transact()
  end

  def create_feature_rule_with_revision(feature, user, attrs) do
    feature
    |> start_revision(user, attrs)
    |> update_attrs(attrs)
    |> Multi.insert(:feature_rule, fn %{update_attrs: attrs} ->
      FeatureRule.changeset(%FeatureRule{}, attrs)
    end)
    |> Repo.transact()
  end

  def update_feature_rule_with_revision(feature_rule, feature, user, attrs \\ %{}) do
    feature
    |> start_revision(user, attrs)
    |> update_attrs(attrs)
    |> Multi.update(:feature_rule, fn %{
                                        update_attrs: attrs,
                                        feature_rules_revision: feature_rules_revision
                                      } ->
      feature_rule_to_update =
        if feature_rules_revision do
          Map.get(feature_rules_revision, feature_rule.id)
        else
          feature_rule
        end

      FeatureRule.changeset(feature_rule_to_update, attrs)
    end)
    |> Repo.transact()
  end

  def delete_feature_rule_with_revision(feature_rule, feature, user) do
    feature
    |> start_revision(user, %{})
    |> Multi.delete(:feature_rule, fn %{
                                        feature_rules_revision: feature_rules_revision
                                      } ->
      if feature_rules_revision do
        Map.get(feature_rules_revision, feature_rule.id)
      else
        feature_rule
      end
    end)
    |> Repo.transact()
  end

  defp update_attrs(multi, attrs) do
    Multi.run(multi, :update_attrs, fn _repo,
                                       %{feature: feature, feature_revision: feature_revision} ->
      if feature_revision do
        {:ok, Map.put(attrs, "feature_revision_id", feature_revision.id)}
      else
        {:ok, Map.put(attrs, "feature_revision_id", feature.last_feature_revision.id)}
      end
    end)
  end

  defp start_revision(feature, user, attrs) do
    Multi.new()
    |> Multi.put(:feature, feature)
    |> Multi.put(:attrs, attrs)
    |> Multi.put(:user, user)
    |> create_feature_revision()
    |> create_feature_rules_revision()
  end

  defp create_feature_revision(multi) do
    Multi.run(multi, :feature_revision, fn _repo, %{feature: feature, user: user} ->
      with :published <- feature.last_feature_revision.status,
           {:ok, feature_revision} <- create_draft_feature_revision(feature, user) do
        {:ok, feature_revision}
      else
        status when status == :draft -> {:ok, nil}
      end
    end)
  end

  def create_feature_rules_revision(multi) do
    Multi.run(multi, :feature_rules_revision, fn _repo,
                                                 %{
                                                   feature: feature,
                                                   feature_revision: feature_revision
                                                 } ->
      if feature_revision do
        create_feature_rules_for_revision(
          feature.last_feature_revision,
          feature_revision
        )
      else
        {:ok, nil}
      end
    end)
  end

  def create_draft_feature_revision(feature, user) do
    Features.create_feature_revision(%{
      feature_id: feature.id,
      revision_number: feature.last_feature_revision.revision_number + 1,
      status: :draft,
      value: %{
        value: feature.last_feature_revision.value.value,
        type: feature.last_feature_revision.value.type
      },
      created_by_id: user.id,
      updated_by_id: user.id
    })
  end

  def create_feature_rules_for_revision(old_feature_revision, new_feature_revision) do
    feature_rules_for_revision =
      Enum.reduce(old_feature_revision.feature_rules, %{}, fn feature_rule, acc ->
        {:ok, revision_feature_rule} =
          Features.create_feature_rule(%{
            feature_revision_id: new_feature_revision.id,
            description: feature_rule.description,
            environment_id: feature_rule.environment_id,
            scheduled: feature_rule.scheduled,
            scheduled_at: feature_rule.scheduled_at,
            value: %{
              value: feature_rule.value.value,
              type: feature_rule.value.type
            },
            conditions:
              Enum.map(feature_rule.conditions, fn condition ->
                Map.from_struct(condition)
              end),
            position: feature_rule.position
          })

        Map.put(acc, feature_rule.id, revision_feature_rule)
      end)

    {:ok, feature_rules_for_revision}
  end
end
