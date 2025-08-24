defmodule SavvyFlagsWeb.AttributeLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import SavvyFlags.AttributesFixtures
  import SavvyFlags.AccountsFixtures

  describe "Index" do
    setup %{conn: conn} = ctx do
      user = user_fixture(%{role: :owner})
      conn = if ctx[:sign_in], do: log_in_user(conn, user), else: conn

      attribute =
        attribute_fixture(%{name: "attropcool"})

      attribute = SavvyFlags.Repo.preload(attribute, :feature_rule_conditions)

      %{conn: conn, user: user, attribute: attribute}
    end

    test "not logged in user must be redirected to login page", %{
      conn: conn
    } do
      result =
        live(conn, ~p"/attributes")
        |> follow_redirect(conn, "/users/log_in")

      assert {:ok, _conn} = result
    end

    @tag :sign_in
    test "logged in user should get the list all attributes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/attributes")
      assert html =~ "Listing attributes"
    end

    @tag :sign_in
    test "logged in user should be able to create a new attribute", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/attributes")

      assert lv |> element("a", "New Attribute") |> render_click() =~
               "New Attribute"

      assert_patch(lv, ~p"/attributes/new")

      assert lv
             |> form("#attribute-form", attribute: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert lv
             |> form("#attribute-form", attribute: %{name: "test"})
             |> render_submit()

      assert_patch(lv, ~p"/attributes")

      html = render(lv)
      assert html =~ "Attribute created successfully"
    end

    @tag :sign_in
    test "logged in user should be able updates attribute from the list", %{
      conn: conn,
      attribute: attribute
    } do
      {:ok, lv, _html} = live(conn, ~p"/attributes")

      assert lv
             |> element("##{attribute.reference} a", "Edit")
             |> render_click() =~
               "Edit attribute"

      assert_patch(lv, ~p"/attributes/#{attribute.reference}/edit")

      assert lv
             |> form("#attribute-form", attribute: %{name: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert lv
             |> form("#attribute-form", attribute: %{name: "attribute"})
             |> render_submit()

      assert_patch(lv, ~p"/attributes")

      html = render(lv)
      assert html =~ "Attribute updated successfully"
    end
  end
end
