defmodule SavvyFlags.FeaturesFixtures do
  def unique_key, do: "feat:#{System.unique_integer()}"

  def feature_fixture(attrs \\ %{}) do
    {:ok, feature} =
      attrs
      |> Enum.into(%{key: unique_key(), default_value: %{type: :boolean, value: "false"}})
      |> SavvyFlags.Features.create_feature()

    feature
  end

  def feature_rule_fixture(attrs \\ %{}) do
    {:ok, feature_rule} =
      attrs
      |> Enum.into(%{})
      |> SavvyFlags.Features.create_feature_rule()

    feature_rule
  end
end
