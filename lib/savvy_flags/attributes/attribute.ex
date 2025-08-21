defmodule SavvyFlags.Attributes.Attribute do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "attributes" do
    field :name, :string
    field :data_type, Ecto.Enum, values: [:boolean, :string, :number], default: :string
    field :identifier, :boolean
    field :description, :string
    field :remote, :boolean
    field :url, :string
    field :feature_rule_conditions_count, :integer, virtual: true
    # FIXME: must be encrypted
    field :access_token, :string
    prefixed_reference :attribute
    has_many :feature_rule_conditions, SavvyFlags.Features.FeatureRuleCondition

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attribute, attrs) do
    attribute
    |> cast(attrs, [
      :name,
      :data_type,
      :identifier,
      :description,
      :remote,
      :url,
      :access_token
    ])
    |> validate_length(:description, max: 150)
    |> validate_required([:name, :data_type])
  end

  def data_types do
    [String: "string", Boolean: "boolean", Number: "number"]
  end

  def default_attributes do
    [
      %{name: "id", data_type: :string, identifier: true},
      %{name: "email", data_type: :string, identifier: true},
      %{name: "deviceId", data_type: :string, identifier: true},
      %{name: "loggedIn", data_type: :boolean},
      %{name: "country", data_type: :string}
    ]
  end

  def prefix do
    SavvyFlags.PrefixedId.prefix(:attribute)
  end
end
