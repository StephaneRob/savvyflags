defmodule SavvyFlagsWeb.HomeLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Show" do
    setup %{conn: conn} do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      conn = log_in_user(conn, user)
      %{conn: conn}
    end

    @tag :sign_in
    test "displays homepage", %{conn: conn} do
      {:error, {:redirect, %{to: "/features"}}} = live(conn, ~p"/home")
    end
  end
end
