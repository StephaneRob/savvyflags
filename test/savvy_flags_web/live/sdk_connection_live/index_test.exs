defmodule SavvyFlagsWeb.SdkConnectionLive.IndexTest do
  alias SavvyFlags.Projects
  alias SavvyFlags.Environments
  alias SavvyFlags.SdkConnections.SdkConnection
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.SdkConnectionsFixtures

  describe "Index" do
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

      %{
        conn: conn,
        user: user,
        sdk_connection: sdk_connection,
        projects: projects,
        environments: environments
      }
    end

    test "not logged_in user lists all sdk_connections for a given oranization", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/sdk-connections")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "lists all sdk connections for a given oranization", %{
      conn: conn
    } do
      {:ok, _index_live, html} = live(conn, ~p"/sdk-connections")
      assert html =~ "Listing SDK connections"
    end

    @tag :sign_in
    test "saves new sdk connections", %{conn: conn, projects: projects} do
      {:ok, index_live, _html} = live(conn, ~p"/sdk-connections")

      assert index_live |> element("a", "New SDK connection") |> render_click() =~
               "New SDK connection"

      assert_patch(index_live, ~p"/sdk-connections/new")

      assert index_live
             |> form("#sdk-connection-form", sdk_connection: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert length(SavvyFlags.Repo.all(SdkConnection)) == 1

      assert index_live
             |> form("#sdk-connection-form",
               sdk_connection: %{
                 name: "test",
                 mode: "remote_evaluated",
                 project_ids: [List.first(projects).id]
               }
             )
             |> render_submit()

      assert length(SavvyFlags.Repo.all(SdkConnection)) == 2

      assert_patch(index_live, ~p"/sdk-connections")

      html = render(index_live)
      assert html =~ "SDK connection created successfully"
    end
  end
end
