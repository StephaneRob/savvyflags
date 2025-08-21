defmodule SavvyFlagsWeb.Api.FallbackControllerTest do
  alias SavvyFlags.Attributes.Attribute
  use SavvyFlagsWeb.ConnCase, async: true

  import SavvyFlags.AttributesFixtures

  setup %{conn: conn} do
    plug_parser =
      Plug.Parsers.init(
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library()
      )

    conn =
      conn
      |> Phoenix.Controller.put_format(:json)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Parsers.call(plug_parser)

    {:ok, conn: conn}
  end

  test "returns 404 when resource not found", %{conn: conn} do
    conn = SavvyFlagsWeb.Api.FallbackController.call(conn, nil)
    assert json_response(conn, 404)["error"] == "Not Found"
  end

  test "returns 422 for changeset errors", %{conn: conn} do
    attribute = attribute_fixture(name: "name")
    changeset = Attribute.changeset(attribute, %{name: ""})
    conn = SavvyFlagsWeb.Api.FallbackController.call(conn, {:error, changeset})
    assert json_response(conn, 422)["errors"] != nil
  end
end
