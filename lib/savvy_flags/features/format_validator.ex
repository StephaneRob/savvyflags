defmodule SavvyFlags.Features.FormatValidator do
  def build_regex(format) do
    format
    |> extract_placeholders()
    |> String.replace("YYYY", "(?<year>\\d{4})")
    |> String.replace("MM", "(?<month>\\d{2})")
    |> String.replace("DD", "(?<day>\\d{2})")
    |> then(&"^#{&1}$")
    |> Regex.compile!()
  end

  defp extract_placeholders(format) do
    Regex.replace(~r/<([^>]+)>/, format, fn _, name ->
      "(?<#{name}>[a-zA-Z0-9-]+)"
    end)
  end

  def validate(nil, _), do: {:ok, %{}}

  def validate(string, format) do
    regex = build_regex(format)

    case Regex.named_captures(regex, string) do
      nil -> {:error, :no_match}
      captures -> {:ok, captures}
    end
  end
end
