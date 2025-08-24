defmodule SavvyFlagsWeb.ProjectLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.ProjectsFixtures

  describe "Index" do
    setup %{conn: conn} = ctx do
      user = SavvyFlags.AccountsFixtures.user_fixture(%{role: :owner})
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn

      project =
        project_fixture(%{name: "Pricing"})

      %{conn: conn, project: project}
    end

    test "not logged in user must be redirected to login page", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/projects")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "logged in user should get the list all projects", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/projects")
      assert html =~ "Listing project"
    end

    @tag :sign_in
    test "logged in user should be able to create a new project", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/projects")

      assert lv |> element("a", "New project") |> render_click() =~
               "New project"

      assert_patch(lv, ~p"/projects/new")

      assert lv
             |> form("#project-form", project: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert lv
             |> form("#project-form", project: %{name: "test"})
             |> render_submit()

      assert_patch(lv, ~p"/projects")

      html = render(lv)
      assert html =~ "Project created successfully"
    end

    @tag :sign_in
    test "logged in user should be able updates project from the list", %{
      conn: conn,
      project: project
    } do
      {:ok, lv, _html} = live(conn, ~p"/projects")

      assert lv
             |> element("##{project.reference} a", "Edit")
             |> render_click() =~
               "Edit project"

      assert_patch(lv, ~p"/projects/#{project.reference}/edit")

      assert lv
             |> form("#project-form", project: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert lv
             |> form("#project-form", project: %{name: "project"})
             |> render_submit()

      assert_patch(lv, ~p"/projects")

      html = render(lv)
      assert html =~ "Project updated successfully"
    end
  end
end
