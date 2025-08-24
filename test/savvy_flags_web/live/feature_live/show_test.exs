defmodule SavvyFlagsWeb.FeatureLive.ShowTest do
  use SavvyFlagsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SavvyFlags.FeaturesFixtures
  import SavvyFlags.EnvironmentsFixtures
  import SavvyFlags.AccountsFixtures
  import SavvyFlags.ProjectsFixtures

  alias SavvyFlags.Projects

  setup %{conn: conn} = ctx do
    user = user_fixture(%{role: :owner})
    environment = environment_fixture()
    project = project_fixture()
    conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn
    projects = Projects.list_projects()

    feature =
      feature_fixture(%{
        project_id: List.first(projects).id
      })

    %{conn: conn, user: user, feature: feature, project: project, environment: environment}
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
  test "logged_in user get access to feature", %{
    conn: conn,
    feature: feature,
    environment: environment
  } do
    {:ok, lv, html} =
      live(conn, ~p"/features/#{feature}")

    assert html =~ "Type"
    assert html =~ "boolean"
    assert html =~ feature.key

    assert lv
           |> element("table tbody#feature-environments td:first-child")
           |> render_click() =~ "Add rule"

    assert_patch(lv, ~p"/features/#{feature}/environments/#{environment}")

    html = render(lv)
    assert html =~ environment.name
    assert html =~ "Add rule"

    assert lv
           |> element("a", "Add rule")
           |> render_click() =~ "New rule"

    assert_patch(lv, ~p"/features/#{feature}/environments/#{environment}/rules/new")

    assert lv
           |> form("#feature-rule-form", feature_rule: %{description: nil})
           |> render_change() =~ "can&#39;t be blank"

    assert lv
           |> form("#feature-rule-form",
             feature_rule: %{description: "My rule", value: %{value: true}}
           )
           |> render_submit()

    assert render(lv) =~ "Feature rule created successfully"
    assert_patch(lv, ~p"/features/#{feature}/environments/#{environment}")
  end
end
