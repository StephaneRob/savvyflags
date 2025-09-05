defmodule SavvyFlags.Features.Evaluator do
  alias SavvyFlags.FeatureCache
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.Rule
  alias SavvyFlags.Features.RuleCondition

  def eval(features, params) when is_list(features) do
    features
    |> Enum.into(%{}, &{&1.key, eval(&1, params)})
  end

  def eval(%Feature{} = feature, params) do
    current_revision = feature.current_revision
    value = current_revision.value.value

    Enum.reduce_while(current_revision.rules, value, fn rule, initial_value ->
      if eval(rule, params) do
        {:halt, rule.value.value}
      else
        {:cont, initial_value}
      end
    end)
  end

  def eval(%Rule{} = rule, params) do
    Enum.all?(rule.conditions, fn condition ->
      eval(condition, params)
    end)
  end

  def eval(%RuleCondition{} = condition, params) do
    attribute_value =
      Map.get(params, condition.attribute) ||
        Map.get(params, :"#{condition.attribute}") || ""

    compare(
      attribute_value,
      maybe_parse(condition.value),
      condition.type
    )
  end

  def compare(attribute_value, value, :match_regex) do
    Regex.match?(~r/#{value}/, attribute_value)
  end

  def compare(attribute_value, value, :not_match_regex) do
    !Regex.match?(~r/#{value}/, attribute_value)
  end

  def compare(attribute_value, value, :equal) do
    attribute_value == value
  end

  def compare(attribute_value, value, :not_equal) do
    attribute_value != value
  end

  def compare("", _, type) when type in [:gt, :gt_or_equal, :lt, :lt_or_equal] do
    false
  end

  def compare(attribute_value, value, type)
      when type in [:gt, :gt_or_equal, :lt, :lt_or_equal] do
    attribute_value = parse_value(attribute_value)
    value = parse_value(value)

    case type do
      :gt -> attribute_value > value
      :gt_or_equal -> attribute_value >= value
      :lt -> attribute_value < value
      :lt_or_equal -> attribute_value <= value
    end
  end

  def compare(attribute_value, value, :in) do
    value = String.split(value, ",") |> Enum.map(&String.trim(&1))
    attribute_value in value
  end

  def compare(attribute_value, value, :not_in) do
    value = String.split(value, ",") |> Enum.map(&String.trim(&1))
    attribute_value not in value
  end

  def compare(nil, _, :sample) do
    false
  end

  def compare(attribute_value, value, :sample) do
    normalized_number = rem(Murmur.hash_x86_32(attribute_value, 0), 100) + 1
    normalized_number < String.to_integer(value)
  end

  defp parse_value(value) when is_integer(value) do
    value / 100 * 100
  end

  defp parse_value(value) when is_binary(value) do
    {value, _} = Float.parse(value)
    value
  end

  def build_plain_payload(sdk_connection, features, cache \\ true) do
    Enum.reduce(features, %{}, fn feature, acc ->
      cache &&
        FeatureCache.push_unique("feature:#{feature.reference}:sdks", sdk_connection.reference)

      current_revision = feature.current_revision

      Map.put(acc, :"#{feature.key}", %{
        default_value: current_revision.value.value,
        type: current_revision.value.type,
        rules:
          Enum.map(current_revision.rules, fn fr ->
            %{
              value: maybe_parse(fr.value.value),
              condition:
                Enum.reduce(fr.conditions, %{}, fn frc, acc2 ->
                  Map.put(acc2, :"#{frc.attribute}", %{
                    "#{frc.type}": maybe_parse(frc.value, frc.type)
                  })
                end)
            }
          end)
      })
    end)
  end

  defp maybe_parse(value, type \\ nil)

  defp maybe_parse(value, type) when type in [:in, :not_in] do
    value
    |> String.split(",")
    |> Enum.map(&maybe_parse(&1, nil))
  end

  defp maybe_parse(value, _) do
    case Integer.parse(value) do
      {value, ""} ->
        value

      {_, ".0"} ->
        {value, _} = Float.parse(value)
        value

      _ ->
        value
    end
  end
end
