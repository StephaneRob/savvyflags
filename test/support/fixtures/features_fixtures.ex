defmodule SavvyFlags.FeaturesFixtures do
  alias SavvyFlags.Features
  alias SavvyFlags.Repo
  def unique_key, do: "feat:#{System.unique_integer()}"

  def feature_fixture(attrs \\ %{}) do
    {:ok, feature} =
      attrs
      |> Enum.into(%{
        key: unique_key(),
        revisions: [
          %{
            value: %{
              type: :boolean,
              value: "false"
            },
            created_by_id: attrs[:current_user_id],
            updated_by_id: attrs[:current_user_id]
          }
        ]
      })
      |> SavvyFlags.Features.create_feature()

    feature
    |> Repo.preload(Features.default_feature_preloads())
  end

  def feature_with_published_revision_fixture(attrs \\ %{}) do
    {:ok, feature} =
      attrs
      |> Enum.into(%{
        key: unique_key(),
        revisions: [
          %{
            value: %{
              type: :boolean,
              value: "false"
            },
            created_by_id: attrs[:current_user_id],
            updated_by_id: attrs[:current_user_id],
            status: :published
          }
        ]
      })
      |> SavvyFlags.Features.create_feature()

    feature
    |> Repo.preload(Features.default_feature_preloads())
  end

  def rule_fixture(attrs \\ %{}) do
    {:ok, rule} =
      attrs
      |> Enum.into(%{})
      |> SavvyFlags.Features.create_rule()

    rule
  end
end
