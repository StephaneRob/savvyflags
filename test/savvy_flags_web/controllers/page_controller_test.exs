defmodule SavvyFlagsWeb.PageControllerTest do
  use SavvyFlagsWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log_in"
  end
end
