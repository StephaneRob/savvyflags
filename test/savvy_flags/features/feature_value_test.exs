defmodule SavvyFlags.Features.FeatureValueTest do
  use SavvyFlags.DataCase
  alias SavvyFlags.Features.FeatureValue

  test "changeset/2" do
    attrs = %{value: "4", type: :number}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)

    assert Ecto.Changeset.apply_changes(changeset) == %FeatureValue{
             value: "4",
             type: :number
           }

    attrs = %{value: "4", type: :string}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)

    assert Ecto.Changeset.apply_changes(changeset) == %FeatureValue{
             value: "4",
             type: :string
           }

    attrs = %{value: "{\"test\": \"coucou\"}", type: :json}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)

    assert Ecto.Changeset.apply_changes(changeset) == %FeatureValue{
             type: :json,
             value: "{\"test\": \"coucou\"}"
           }

    attrs = %{value: "[{\"test\": \"coucou\"}]", type: :json}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)

    assert Ecto.Changeset.apply_changes(changeset) == %FeatureValue{
             type: :json,
             value: "[{\"test\": \"coucou\"}]"
           }

    attrs = %{value: "true", type: :boolean}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)

    assert Ecto.Changeset.apply_changes(changeset) == %FeatureValue{
             type: :boolean,
             value: "true"
           }

    attrs = %{value: nil, type: :number}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)
    assert changeset.errors == [{:value, {"Value is required", []}}]

    attrs = %{value: "azerty", type: :number}
    assert changeset = FeatureValue.changeset(%FeatureValue{}, attrs)
    assert changeset.errors == [{:value, {"Value must be a valid number", []}}]
  end
end
