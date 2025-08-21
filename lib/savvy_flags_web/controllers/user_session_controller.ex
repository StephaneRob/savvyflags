defmodule SavvyFlagsWeb.UserSessionController do
  use SavvyFlagsWeb, :controller

  alias SavvyFlags.Accounts
  alias SavvyFlagsWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def mfa(conn, %{"mfa" => %{"code" => code}}) do
    current_user = conn.assigns.current_user
    attemtps = get_session(conn, :mfa_failed_attempts, 0)

    if NimbleTOTP.valid?(current_user.secret, code) do
      conn
      |> delete_session(:mfa_requested_at)
      |> delete_session(:mfa_failed_attempts)
      |> redirect(to: ~p"/")
    else
      handle_mfa_error(conn, attemtps)
    end
  end

  defp handle_mfa_error(conn, 2) do
    conn
    |> put_flash(:error, "You've been logged out, after 3 failed code")
    |> UserAuth.log_out_user()
  end

  defp handle_mfa_error(conn, attempts) do
    conn
    |> put_flash(:error, "Invalid code")
    |> put_session(:mfa_failed_attempts, attempts + 1)
    |> redirect(to: ~p"/users/log_in/mfa")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
