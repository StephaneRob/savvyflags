defmodule SavvyFlagsWeb.UserLoginMfaLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SavvyFlags.AccountsFixtures

  describe "Mfa page" do
    setup %{conn: conn} do
      secret = NimbleTOTP.secret()
      user = user_fixture(%{secret: secret})

      conn =
        conn
        |> log_in_user(user)
        |> put_session(:mfa_requested_at, DateTime.utc_now() |> DateTime.to_unix())

      %{conn: conn, user: user}
    end

    test "renders mfa page", %{conn: conn, user: user} do
      {:ok, lv, html} = live(conn, ~p"/users/log_in/mfa")

      assert html =~ "Verify your account"
      assert html =~ "Code *"

      form =
        form(lv, "#mfa_form", mfa: %{code: "123456"})

      conn = submit_form(form, conn)
      assert redirected_to(conn) == ~p"/users/log_in/mfa"

      form =
        form(lv, "#mfa_form", mfa: %{code: NimbleTOTP.verification_code(user.secret)})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :mfa_requested_at)
    end
  end
end
