defmodule SavvyFlagsWeb.UserInvitationLiveTest do
  use SavvyFlagsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias SavvyFlags.Accounts

  test "must redirect to home page with invalid invitation token", %{
    conn: conn
  } do
    result =
      live(conn, ~p"/users/invitation/coucou")
      |> follow_redirect(conn, "/")

    assert {:ok, conn} = result

    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
             "Invitation link is invalid or it has expired. Please contact your administrator"
  end

  test "must display form with valid invitation token", %{conn: conn} do
    {:ok, user} =
      Accounts.invite_user(%{"email" => "stephane.robino+1@gmail.com", "role" => :admin})

    {encoded_token, user_token} =
      SavvyFlags.Accounts.UserToken.build_email_token(user, "invitation")

    SavvyFlags.Repo.insert!(user_token)
    {:ok, live, html} = live(conn, ~p"/users/invitation/#{encoded_token}")
    assert html =~ "You&#39;ve been invited to join SavvyFlags"

    assert live
           |> form("#invitation_form", user: %{password: nil, password_confirmation: nil})
           |> render_change() =~ "can&#39;t be blank"

    assert live =
             live
             |> form("#invitation_form",
               user: %{password: "azertyazerty", password_confirmation: "azertyazerty"}
             )
             |> render_submit()

    result = follow_redirect(live, conn, ~p"/users/log_in")
    assert {:ok, conn} = result

    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
             "Account successfully completed. Please log in using your email / password"
  end
end
