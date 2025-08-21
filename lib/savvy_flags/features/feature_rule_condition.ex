defmodule SavvyFlags.Features.FeatureRuleCondition do
  use Ecto.Schema
  import Ecto.Changeset
  import SavvyFlags.Fields

  @types [
    Equal: :equal,
    "Not equal": :not_equal,
    "Match Regex": :match_regex,
    "Doesn't match regex": :not_match_regex,
    "Greater than": :gt,
    "Greater or equal than": :gt_or_equal,
    "Less than": :lt,
    "Less or equal than": :lt_or_equal,
    "In list": :in,
    "Not in list": :not_in,
    Exists: :exists,
    "Doesn't exist": :not_exist,
    Sample: :sample
  ]

  @derive {Phoenix.Param, key: :reference}
  schema "feature_rule_conditions" do
    field :position, :integer
    prefixed_reference :feature_rule_condition
    field :value, :string
    field :type, Ecto.Enum, values: Keyword.values(@types)
    field :delete, :boolean, virtual: true
    belongs_to :feature_rule, SavvyFlags.Features.FeatureRule
    belongs_to :attribute, SavvyFlags.Attributes.Attribute

    timestamps(type: :utc_datetime)
  end

  def changeset(feature_rule_condition, attrs) do
    feature_rule_condition
    |> cast(attrs, [:position, :value, :type, :attribute_id, :delete])
    |> validate_required([:position, :value, :type, :attribute_id])
    |> flag_delete()
  end

  defp flag_delete(changeset) do
    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end

  def types do
    @types
  end

  def mapping do
    for {k, v} <- @types, into: [], do: {v, k}
  end
end
