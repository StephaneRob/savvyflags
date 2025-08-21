defmodule SavvyFlagsWeb.Api.FallbackJSON do
  alias Ecto.Changeset

  def not_found(_) do
    %{error: "Not Found"}
  end

  def error(%{changeset: changeset}) do
    %{errors: error_codes(changeset)}
  end

  def error_codes(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, opts} ->
      %{
        message: msg,
        options: opts |> Enum.into(%{}, &format_opts/1)
      }
    end)
  end

  defp format_opts({key, val}) when is_map(val), do: {key, inspect(val)}
  defp format_opts({key, val}) when is_tuple(val), do: {key, inspect(val)}
  defp format_opts({key, val}), do: {key, val}
end
