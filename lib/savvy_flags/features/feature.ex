defmodule SavvyFlags.Features.Feature do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset
  alias SavvyFlags.Features.FeatureValue
  alias SavvyFlags.Features.FormatValidator

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

  def create_changeset(feature, attrs) do
    feature
    |> changeset(attrs)
    |> validate_key_format()
  end

  @doc false
  def changeset(feature, attrs) do
    feature
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

  defp validate_key_format(changeset) do
    # TODO: stop loading configuration on every validation
    configuration = SavvyFlags.Configurations.get_configuration()

    if configuration.feature_key_format in [nil, ""] do
      changeset
    else
      do_validate_key_format(changeset, configuration.feature_key_format)
    end
  end

  defp do_validate_key_format(changeset, format) do
    case FormatValidator.validate(get_field(changeset, :key), format) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, :key, "Key must match the format: #{format}")
    end
  end
end
