defmodule SavvyFlags.Utils do
  def build_defaults(default_values, object) do
    default_values
    |> Enum.map(
      &Map.merge(&1, %{
        inserted_at: DateTime.truncate(DateTime.utc_now(), :second),
        updated_at: DateTime.truncate(DateTime.utc_now(), :second),
        reference: SavvyFlags.PrefixedId.generate(object)
      })
    )
  end

  def get_value(map, attr, default \\ nil) do
    if Map.has_key?(map, attr) do
      Map.get(map, attr, default)
    else
      Map.get(map, "#{attr}", default)
    end
  end
end
