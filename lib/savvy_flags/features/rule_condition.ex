defmodule SavvyFlags.Features.RuleCondition do
  use Ecto.Schema
  import Ecto.Changeset

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

  @mapping Enum.into(@types, [], fn {k, v} -> {v, k} end)

  embedded_schema do
    field :attribute, :string
    field :value, :string
    field :type, Ecto.Enum, values: Keyword.values(@types)
  end

  def changeset(rule_condition, attrs) do
    rule_condition
    |> cast(attrs, [:value, :type, :attribute])
    |> validate_required([:value, :type, :attribute])
  end

  def types do
    @types
  end

  def mapping do
    @mapping
  end
end
