defmodule SavvyFlagsWeb.EnvironmentLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.EnvironmentsFixtures

  describe "Index" do
    setup %{conn: conn} = ctx do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn

      environment =
        environment_fixture(%{name: "preprod5"})

      %{conn: conn, user: user, environment: environment}
    end

    test "not logged in user must be redirected to login page", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/environments")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "logged in user should get the list all environments", %{
      conn: conn
    } do
      {:ok, _index_live, html} = live(conn, ~p"/environments")
      assert html =~ "Listing environments"
    end

    @tag :sign_in
    test "logged in user should be able to create a new environment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/environments")

      assert index_live |> element("a", "New Environment") |> render_click() =~
               "New Environment"

      assert_patch(index_live, ~p"/environments/new")

      assert index_live
             |> form("#environment-form", environment: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#environment-form", environment: %{name: "test"})
             |> render_submit()

      assert_patch(index_live, ~p"/environments")

      html = render(index_live)
      assert html =~ "Environment created successfully"
    end

    @tag :sign_in
    test "logged in user should be able updates environment from the list", %{
      conn: conn,
      environment: environment
    } do
      {:ok, index_live, _html} = live(conn, ~p"/environments")

      assert index_live
             |> element("##{environment.reference} a", "Edit")
             |> render_click() =~
               "Edit environment"

      assert_patch(index_live, ~p"/environments/#{environment.reference}/edit")

      assert index_live
             |> form("#environment-form", environment: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#environment-form", environment: %{name: "environment"})
             |> render_submit()

      assert_patch(index_live, ~p"/environments")

      html = render(index_live)
      assert html =~ "Environment updated successfully"
    end
  end
end
