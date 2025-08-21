defmodule SavvyFlagsWeb.Api.FallbackController do
  use Phoenix.Controller, formats: [:html, :json]

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: SavvyFlagsWeb.Api.FallbackJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(json: SavvyFlagsWeb.Api.FallbackJSON)
    |> render(:not_found)
  end
end
