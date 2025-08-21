defmodule SavvyFlagsWeb.UserLoginLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SavvyFlags.AccountsFixtures

  describe "Log in page without any user" do
    test "redirect to first_run", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/first_run"}}} = live(conn, ~p"/users/log_in")
    end
  end

  describe "Log in page" do
    setup do
      user_fixture()
      :ok
    end

    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Log in"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/log_in")
        |> follow_redirect(conn, ~p"/home")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    setup do
      user_fixture()
      :ok
    end

    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/home"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form",
          user: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/users/log_in"
    end
  end

  describe "login navigation" do
    setup do
      user_fixture()
      :ok
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, conn} =
        lv
        |> element("main a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/reset_password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end

  describe "redirect to mfa" do
    setup do
      password = "123456789abcd"
      secret = NimbleTOTP.secret()
      user = user_fixture(%{secret: secret, password: password})
      uri = NimbleTOTP.otpauth_uri(user.reference, secret, issuer: "SavvyFlags")

      %{user: user, uri: uri, password: password}
    end

    test "must redirect to mfa after login in mfa_enabled", %{
      conn: conn,
      user: user,
      password: password
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: password})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/users/log_in/mfa"
    end
  end
end
