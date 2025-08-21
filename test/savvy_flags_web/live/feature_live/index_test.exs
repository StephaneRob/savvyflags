defmodule SavvyFlagsWeb.FeatureLive.IndexTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.FeaturesFixtures
  alias SavvyFlags.Projects

  describe "Index" do
    setup %{conn: conn} = ctx do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      SavvyFlags.EnvironmentsFixtures.environment_fixture()
      project = SavvyFlags.ProjectsFixtures.project_fixture()
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn
      projects = Projects.list_projects()

      feature =
        feature_fixture(%{
          project_id: List.first(projects).id
        })

      %{conn: conn, user: user, feature: feature, project: project}
    end

    test "not logged_in user lists all features for a given oranization", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/features")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "lists all features for a given oranization", %{
      conn: conn,
      feature: feature,
      project: project
    } do
      {:ok, live, html} = live(conn, ~p"/features")
      assert html =~ "Features"
      assert html =~ feature.key

      assert live
             |> form("#features_search",
               filter: %{project_id: project.id, value_type: :boolean}
             )
             |> render_change() =~ feature.key

      refute live
             |> form("#features_search",
               filter: %{project_id: project.id, value_type: :string}
             )
             |> render_change() =~ feature.key
    end

    @tag :sign_in
    test "Create a new feature", %{
      conn: conn
    } do
      {:ok, index_live, _html} = live(conn, ~p"/features")

      assert index_live |> element("a", "New feature") |> render_click() =~
               "New feature"

      assert_patch(index_live, ~p"/features/new")

      assert index_live
             |> form("#feature-form", feature: %{key: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#feature-form",
               feature: %{key: "test:1", default_value: %{type: "string", value: "green"}}
             )
             |> render_submit()

      {path, _flash} = assert_redirect(index_live)
      assert path =~ ~r/\/features\/f_\w+/
    end
  end
end
