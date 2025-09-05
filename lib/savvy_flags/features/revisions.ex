defmodule SavvyFlags.Features.Revisions do
  @dialyzer {:nowarn_function,
             start_revision: 3, publish_revision: 1, discard_revision: 1, rollback_to: 1}

  import Ecto.Query, warn: false

  alias SavvyFlags.Utils
  alias Ecto.Multi
  alias SavvyFlags.Repo
  alias SavvyFlags.Features
  alias SavvyFlags.Features.Rule
  alias SavvyFlags.Features.Revision

  def rollback_to(revision) do
    Multi.new()
    |> Multi.delete_all(
      :unpublish_others,
      from(fr in Revision,
        where:
          fr.feature_id == ^revision.feature_id and
            fr.revision_number > ^revision.revision_number
      ),
      set: [status: :unpublished]
    )
    |> Multi.update(
      :publish_revision,
      Revision.changeset(revision, %{status: :published})
    )
    |> Repo.transact()
  end

  def discard_revision(revision) do
    Multi.new()
    |> Multi.delete(:revision, revision)
    |> Repo.transact()
  end

  def publish_revision(revision) do
    Multi.new()
    |> Multi.update_all(
      :unpublish_others,
      from(fr in Revision,
        where: fr.feature_id == ^revision.feature_id and fr.id != ^revision.id
      ),
      set: [status: :unpublished]
    )
    |> Multi.update(
      :publish_revision,
      Revision.changeset(revision, %{status: :published})
    )
    |> Repo.transact()
  end

  def update_revision(feature, user, attrs) do
    feature
    |> start_revision(user, attrs)
    |> Multi.update(:revision_updated, fn %{
                                            revision: revision,
                                            feature: feature
                                          } ->
      revisions_params = Utils.get_value(attrs, :revisions, %{})
      attrs = Utils.get_value(revisions_params, :"0", %{})

      if revision do
        Features.change_revision(revision, attrs)
      else
        Features.change_revision(feature.last_revision, attrs)
      end
    end)
    |> Repo.transact()
  end

  def create_rule_with_revision(feature, user, attrs) do
    feature
    |> start_revision(user, attrs)
    |> update_attrs(attrs)
    |> Multi.insert(:rule, fn %{update_attrs: attrs} ->
      Rule.changeset(%Rule{}, attrs)
    end)
    |> Repo.transact()
  end

  def update_rule_with_revision(rule, feature, user, attrs \\ %{}) do
    feature
    |> start_revision(user, attrs)
    |> update_attrs(attrs)
    |> Multi.update(:rule, fn %{
                                update_attrs: attrs,
                                rules_revision: rules_revision
                              } ->
      rule_to_update =
        if rules_revision do
          Map.get(rules_revision, rule.id)
        else
          rule
        end

      Rule.changeset(rule_to_update, attrs)
    end)
    |> Repo.transact()
  end

  def delete_rule_with_revision(rule, feature, user) do
    feature
    |> start_revision(user, %{})
    |> Multi.delete(:rule, fn %{
                                rules_revision: rules_revision
                              } ->
      if rules_revision do
        Map.get(rules_revision, rule.id)
      else
        rule
      end
    end)
    |> Repo.transact()
  end

  defp update_attrs(multi, attrs) do
    Multi.run(multi, :update_attrs, fn _repo, %{feature: feature, revision: revision} ->
      if revision do
        {:ok, Map.put(attrs, "revision_id", revision.id)}
      else
        {:ok, Map.put(attrs, "revision_id", feature.last_revision.id)}
      end
    end)
  end

  defp start_revision(feature, user, attrs) do
    Multi.new()
    |> Multi.put(:feature, feature)
    |> Multi.put(:attrs, attrs)
    |> Multi.put(:user, user)
    |> create_revision()
    |> create_rules_revision()
  end

  defp create_revision(multi) do
    Multi.run(multi, :revision, fn _repo, %{feature: feature, user: user} ->
      with :published <- feature.last_revision.status,
           {:ok, revision} <- create_draft_revision(feature, user) do
        {:ok, revision}
      else
        status when status == :draft -> {:ok, nil}
      end
    end)
  end

  def create_rules_revision(multi) do
    Multi.run(multi, :rules_revision, fn _repo,
                                         %{
                                           feature: feature,
                                           revision: revision
                                         } ->
      if revision do
        create_rules_for_revision(
          feature.last_revision,
          revision
        )
      else
        {:ok, nil}
      end
    end)
  end

  def create_draft_revision(feature, user) do
    Features.create_revision(%{
      feature_id: feature.id,
      revision_number: feature.last_revision.revision_number + 1,
      status: :draft,
      value: %{
        value: feature.last_revision.value.value,
        type: feature.last_revision.value.type
      },
      created_by_id: user.id,
      updated_by_id: user.id
    })
  end

  def create_rules_for_revision(old_revision, new_revision) do
    rules_for_revision =
      Enum.reduce(old_revision.rules, %{}, fn rule, acc ->
        {:ok, revision_rule} =
          Features.create_rule(%{
            revision_id: new_revision.id,
            description: rule.description,
            environment_id: rule.environment_id,
            scheduled: rule.scheduled,
            scheduled_at: rule.scheduled_at,
            value: %{
              value: rule.value.value,
              type: rule.value.type
            },
            conditions:
              Enum.map(rule.conditions, fn condition ->
                Map.from_struct(condition)
              end),
            position: rule.position
          })

        Map.put(acc, rule.id, revision_rule)
      end)

    {:ok, rules_for_revision}
  end
end
