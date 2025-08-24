defmodule SavvyFlags.MockAttributes do
  @moduledoc false
  use Plug.Router

  import Plug.Conn

  plug Plug.Parsers,
    parsers: [:json, :urlencoded],
    pass: ["text/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  get "/api/organization_reference" do
    q = String.downcase(conn.params["q"] || "")
    result = Enum.filter(fake_organizations(), &String.contains?(String.downcase(&1.name), q))

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Jason.encode!(result))
  end

  get "*path" do
    send_resp(conn, 200, Jason.encode!(%{ok: true}))
  end

  defp fake_organizations do
    [
      %{name: "Tatooine", value: "1cea6ffd-cddd-4ac3-a1d8-d112681ae196"},
      %{name: "Kamino", value: "8610b010-0eac-4536-977b-a538bb1e4879"},
      %{name: "Naboo", value: "494411c6-dd34-480f-8c98-05f2d85189f4"},
      %{name: "Coruscant", value: "d8aaa398-ce93-498a-8d78-afab7565ab01"},
      %{name: "Dagobah", value: "470843ca-b283-4763-a7b6-d33514f9433e"},
      %{name: "Hoth", value: "8cfb6afd-7332-4b5b-aeef-ea03c40df459"},
      %{name: "Jaku", value: "49a00997-7e7b-46d1-baa2-960b1c95fdcd"},
      %{name: "Alderaan", value: "ea499a61-7eec-4011-99e6-208034934b4c"},
      %{name: "Mustafar", value: "731262f1-2a5c-4c1d-9705-09d6dd5ce818"},
      %{name: "Bespin", value: "b641ac8f-500d-4e8b-bee9-63ba03bc9017"}
    ]
  end
end
