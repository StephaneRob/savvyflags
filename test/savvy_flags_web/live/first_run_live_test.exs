defmodule SavvyFlagsWeb.FirstRunLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SavvyFlags.AccountsFixtures

  describe "First run page" do
    test "renders first run page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/first_run")

      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/first_run")
        |> follow_redirect(conn, "/home")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/first_run")

      result =
        lv
        |> element("#first_run_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Welcome to SavvyFlags!"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register owner" do
    test "creates account and logs the owner in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/first_run")

      email = unique_user_email()
      form = form(lv, "#first_run_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/home"

      # Check a user is created and is owner
      [user] = SavvyFlags.Accounts.list_users()
      assert user.role == :owner

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      assert redirected_to(conn) == ~p"/home"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/first_run")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#first_run_form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end
end
