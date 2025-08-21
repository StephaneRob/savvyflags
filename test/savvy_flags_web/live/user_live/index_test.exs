defmodule SavvyFlagsWeb.UserLive.IndexTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "Index users" do
    setup %{conn: conn} = ctx do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn
      %{conn: conn, user: user}
    end

    test "not logged in user must be redirected to login page", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/users")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    test "member user must be redirected to homepage", %{
      conn: conn
    } do
      user = SavvyFlags.AccountsFixtures.user_fixture()

      result =
        conn
        |> log_in_user(user)
        |> live(~p"/users")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "logged in owner should get the list all users", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/users")
      assert html =~ "Listing users"
    end

    @tag :sign_in
    test "logged in owner should be able to invite a new user", %{
      conn: conn
    } do
      {:ok, view, _} = live(conn, ~p"/users")

      assert view |> element("a", "Invite user") |> render_click() =~
               "New user"

      assert_patch(view, ~p"/users/new")

      assert view
             |> form("#user-form", user: %{email: ""})
             |> render_change() =~ "can&#39;t be blank"
    end
  end
end
