defmodule SavvyFlags.Features.Feature do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset
  alias SavvyFlags.Features.FeatureValue

  @derive {Phoenix.Param, key: :reference}
  schema "features" do
    prefixed_reference :feature
    field :key, :string
    field :description, :string
    field :environments_enabled, {:array, :integer}, default: []
    field :archived_at, :utc_datetime
    embeds_one :default_value, FeatureValue, on_replace: :delete
    belongs_to :project, SavvyFlags.Projects.Project
    has_many :feature_rules, SavvyFlags.Features.FeatureRule
    has_many :environments, through: [:feature_rules, :environment]
    many_to_many :users, SavvyFlags.Accounts.User, join_through: "user_features"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attribute, attrs) do
    attribute
    |> cast(attrs, [
      :key,
      :description,
      :project_id,
      :environments_enabled,
      :archived_at
    ])
    |> cast_embed(:default_value, with: &FeatureValue.changeset/2)
    |> validate_length(:description, max: 150)
    |> validate_required([:key, :project_id])
  end

  def value_types do
    [String: "string", Boolean: "boolean", Number: "number", Json: "json"]
  end
end
