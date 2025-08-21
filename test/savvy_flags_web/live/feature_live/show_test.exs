defmodule SavvyFlagsWeb.FeatureLive.ShowTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.FeaturesFixtures
  alias SavvyFlags.Projects

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

  test "not logged_in user can't access feature", %{
    conn: conn,
    feature: feature
  } do
    result =
      live(conn, ~p"/features/#{feature}")
      |> follow_redirect(conn, "/users/log_in")

    assert {:ok, _conn} = result
  end

  @tag :sign_in
  test "not logged_in user get access to feature", %{
    conn: conn,
    feature: feature
  } do
    {:ok, _, html} =
      live(conn, ~p"/features/#{feature}")

    assert html =~ "Type"
    assert html =~ "boolean"
    assert html =~ feature.key
  end
end
