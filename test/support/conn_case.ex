defmodule SavvyFlagsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use SavvyFlagsWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint SavvyFlagsWeb.Endpoint

      use SavvyFlagsWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import SavvyFlagsWeb.ConnCase
    end
  end

  setup tags do
    SavvyFlags.DataCase.setup_sandbox(tags)
    SavvyFlags.Configurations.init()
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = SavvyFlags.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = SavvyFlags.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def maybe_log_in_user(%{conn: conn, sign_in: sign_in} = context) do
    attrs =
      case sign_in do
        true -> [role: :owner]
        nil -> nil
        value when is_atom(value) -> [role: value]
        attrs -> attrs
      end

    user = SavvyFlags.AccountsFixtures.user_fixture(attrs)
    conn = log_in_user(conn, user)
    Map.merge(context, %{conn: conn, user: user})
  end

  def maybe_log_in_user(ctx) do
    ctx
  end
end
