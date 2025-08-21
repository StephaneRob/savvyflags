defmodule SavvyFlagsWeb.SdkConnectionLive.ShowTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.SdkConnectionsFixtures
  alias SavvyFlags.Projects
  alias SavvyFlags.Environments

  describe "Show" do
    setup %{conn: conn} = ctx do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      SavvyFlags.EnvironmentsFixtures.environment_fixture()
      SavvyFlags.ProjectsFixtures.project_fixture()
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn
      projects = Projects.list_projects()
      environments = Environments.list_environments()

      sdk_connection =
        sdk_connection_fixture(%{
          name: "Production / Global",
          project_ids: [List.first(projects).id],
          environment_id: List.first(environments).id
        })

      %{conn: conn, user: user, sdk_connection: sdk_connection}
    end

    test "not logged_in user can't get sdk_connection for a given oranization", %{
      sdk_connection: sdk_connection,
      conn: conn
    } do
      result =
        live(conn, ~p"/sdk-connections/#{sdk_connection}")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "logged in should get a sdk connections", %{
      sdk_connection: sdk_connection,
      conn: conn
    } do
      {:ok, _index_live, html} =
        live(conn, ~p"/sdk-connections/#{sdk_connection}")

      assert html =~ "#{sdk_connection.reference}"
      assert html =~ "Mode"
      assert html =~ "Plain"
    end

    @tag :sign_in
    test "logged in user should be able to navigate to sandbox or metrics", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      {:ok, index_live, _html} = live(conn, ~p"/sdk-connections/#{sdk_connection}")
      assert index_live |> element("a", "Sandbox") |> render_click() =~ "Plain rules"
      assert_patch(index_live, ~p"/sdk-connections/#{sdk_connection}/sandbox")
      assert index_live |> element("a", "Metrics") |> render_click() =~ "30 days API usage"
      assert_patch(index_live, ~p"/sdk-connections/#{sdk_connection}/metrics")
    end
  end
end
