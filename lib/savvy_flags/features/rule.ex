defmodule SavvyFlags.Features.Rule do
  alias SavvyFlags.Features.FeatureValue
  alias SavvyFlags.Features.RuleCondition
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
    embeds_many :conditions, RuleCondition, on_replace: :delete

    prefixed_reference :rule

    belongs_to :revision, SavvyFlags.Features.Revision
    belongs_to :environment, SavvyFlags.Environments.Environment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :description,
      :revision_id,
      :environment_id,
      :position,
      :scheduled_at,
      :scheduled
    ])
    |> cast_embed(:conditions, with: &RuleCondition.changeset/2)
    |> cast_embed(:value, with: &FeatureValue.changeset/2)
    |> reset_scheduled_at()
    |> validate_length(:description, max: 150)
    |> validate_required([:value, :revision_id, :environment_id, :description, :position])
  end

  defp reset_scheduled_at(changeset) do
    if get_field(changeset, :scheduled) do
      changeset
    else
      put_change(changeset, :scheduled_at, nil)
    end
  end
end
