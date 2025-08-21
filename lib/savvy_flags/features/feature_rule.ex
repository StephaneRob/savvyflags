defmodule SavvyFlags.Features.FeatureRule do
  alias SavvyFlags.Features.FeatureValue
  alias SavvyFlags.Features.FeatureRuleCondition
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "feature_rules" do
    field :description, :string
    field :position, :integer, default: 0
    field :scheduled, :boolean
    field :scheduled_at, :utc_datetime
    field :activated_at, :utc_datetime

    embeds_one :value, FeatureValue, on_replace: :delete
    prefixed_reference :feature_rule

    has_many :feature_rule_conditions, SavvyFlags.Features.FeatureRuleCondition,
      preload_order: [asc: :id],
      on_replace: :delete

    belongs_to :feature, SavvyFlags.Features.Feature
    belongs_to :environment, SavvyFlags.Environments.Environment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feature_rule, attrs) do
    feature_rule
    |> cast(attrs, [
      :description,
      :feature_id,
      :environment_id,
      :position,
      :scheduled_at,
      :scheduled
    ])
    |> cast_assoc(:feature_rule_conditions, with: &FeatureRuleCondition.changeset/2)
    |> cast_embed(:value, with: &FeatureValue.changeset/2)
    |> reset_scheduled_at()
    |> validate_length(:description, max: 150)
    |> validate_required([:value, :feature_id, :environment_id, :description, :position])
  end

  defp reset_scheduled_at(changeset) do
    if get_field(changeset, :scheduled) do
      changeset
    else
      put_change(changeset, :scheduled_at, nil)
    end
  end
end
