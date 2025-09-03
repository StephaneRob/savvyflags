defmodule SavvyFlags.Environments do
  import Ecto.Query, warn: false

  alias SavvyFlags.Repo
  alias SavvyFlags.Features.FeatureRule
  alias SavvyFlags.Environments.Environment

  def get_environment_by_id!(id) do
    Repo.get_by!(Environment, id: id)
  end

  def list_environments(feature, nil) do
    list_environments(feature)
  end

  def list_environments(feature, environment_ids) do
    query =
      from e in Environment,
        where: e.id in ^environment_ids,
        preload: [feature_rules: ^feature_rules_preload_query(feature)]

    Repo.all(query)
  end

  def list_environments(feature) do
    query =
      from e in Environment,
        preload: [feature_rules: ^feature_rules_preload_query(feature)]

    Repo.all(query)
  end

  def list_environments do
    query = from e in Environment, order_by: [asc: e.inserted_at]
    Repo.all(query)
  end

  def get_environment(reference, feature_revision) do
    query =
      from e in Environment,
        where: e.reference == ^reference,
        preload: [feature_rules: ^feature_rules_preload_query(feature_revision)]

    Repo.one(query)
  end

  def get_environment_by_reference!(reference) do
    Repo.get_by!(Environment, reference: reference)
  end

  def update_environment(environment, attrs) do
    environment
    |> Environment.changeset(attrs)
    |> Repo.update()
  end

  def create_environment(attrs) do
    %Environment{}
    |> Environment.changeset(attrs)
    |> Repo.insert()
  end

  def delete_environment(environment) do
    Repo.delete(environment)
  end

  def change_environment(%Environment{} = environment, attrs \\ %{}) do
    Environment.changeset(environment, attrs)
  end

  defp feature_rules_preload_query(feature_revision) do
    from fr in FeatureRule,
      where: fr.feature_revision_id == ^feature_revision.id,
      order_by: [asc: :position]
  end
end
