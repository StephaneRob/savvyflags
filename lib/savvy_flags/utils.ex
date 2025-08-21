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
end
