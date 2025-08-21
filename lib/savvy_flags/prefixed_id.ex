defmodule SavvyFlags.PrefixedId do
  def generate(object) do
    prefix = if p = prefix(object), do: p <> "_", else: ""
    random = :crypto.strong_rand_bytes(32)

    :md5
    |> :crypto.hash(random)
    |> Base.encode64()
    |> Base.url_encode64()
    |> String.slice(0..12)
    |> then(&(prefix <> &1))
  end

  def prefix(object) do
    Map.get(prefixes(), object, "")
  end

  defp prefixes do
    %{
      user: "u",
      environment: "e",
      attribute: "a",
      project: "p",
      sdk_connection: "sdk",
      feature: "f",
      feature_rule: "fr",
      feature_rule_condition: "frc"
    }
  end
end
