defmodule SavvyFlags.Features.FeatureValue do
  use Ecto.Schema
  import Ecto.Changeset

  @mapping %{
    boolean: [:boolean],
    string: [:string],
    number: [:float],
    json: [:map, {:array, :map}]
  }

  @primary_key false
  embedded_schema do
    field :value, :string
    field :type, Ecto.Enum, values: [:boolean, :string, :number, :json], default: :string
  end

  def changeset(feature_value, attrs) do
    feature_value
    |> cast(attrs, [:type])
    |> validate_value(attrs)
  end

  defp validate_value(changeset, attrs) do
    type = get_field(changeset, :type)
    raw_value = get_raw_value(attrs)

    if raw_value in ["", nil] do
      add_error(changeset, :value, "Value is required")
    else
      changeset = validate_value_with_type(changeset, raw_value, type)

      if get_field(changeset, :value) do
        changeset
      else
        add_error(changeset, :value, "Value must be a valid #{type}")
      end
    end
  end

  defp validate_value_with_type(changeset, raw_value, type) do
    mapping_types = Map.get(@mapping, type)

    Enum.reduce_while(mapping_types, changeset, fn mapping_type, changeset ->
      case cast_value(mapping_type, raw_value, type) do
        {:ok, _} ->
          {:halt, put_change(changeset, :value, "#{raw_value}")}

        :error ->
          {:cont, changeset}
      end
    end)
  end

  defp cast_value(mapping_type, raw_value, :json) do
    case Jason.decode(raw_value) do
      {:ok, value} -> Ecto.Type.cast(mapping_type, value)
      _ -> :error
    end
  end

  defp cast_value(mapping_type, raw_value, _) do
    Ecto.Type.cast(mapping_type, raw_value)
  end

  defp get_raw_value(%{"value" => value}) do
    value
  end

  defp get_raw_value(%{value: value}) do
    value
  end

  defp get_raw_value(_) do
    nil
  end
end
