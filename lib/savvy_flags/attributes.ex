defmodule SavvyFlags.Attributes do
  import Ecto.Query, warn: false

  alias SavvyFlags.Repo
  alias SavvyFlags.Attributes.Attribute

  def list_attributes(preloads) do
    list_attributes()
    |> Repo.preload(preloads)
  end

  def list_attributes do
    query =
      from a in Attribute,
        left_join: frc in assoc(a, :feature_rule_conditions),
        select_merge: %{feature_rule_conditions_count: count(frc.reference)},
        order_by: [asc: a.id],
        group_by: a.id

    Repo.all(query)
  end

  def get_attribute_by_reference!(reference) do
    Repo.get_by!(Attribute, reference: reference)
  end

  def get_attribute!(id) do
    Repo.get(Attribute, id)
  end

  def update_attribute(attribute, attrs) do
    attribute
    |> Attribute.changeset(attrs)
    |> Repo.update()
  end

  def create_attribute(attrs) do
    %Attribute{}
    |> Attribute.changeset(attrs)
    |> Repo.insert()
  end

  def delete_attribute(%Attribute{} = attribute) do
    Repo.delete(attribute)
  end

  def change_attribute(%Attribute{} = attribute, attrs \\ %{}) do
    Attribute.changeset(attribute, attrs)
  end
end
