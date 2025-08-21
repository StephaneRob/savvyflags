defmodule SavvyFlagsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :savvy_flags

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_savvy_flags_key",
    signing_salt: "L8u7Kg1p",
    same_site: "Lax"
  ]

  plug :health_check
  plug :auth

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  plug CORSPlug
  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :savvy_flags,
    gzip: false,
    only: SavvyFlagsWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :savvy_flags
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug SavvyFlagsWeb.Router

  def health_check(%Plug.Conn{path_info: ["healthz"]} = conn, _) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Jason.encode!(%{ok: true}))
    |> halt()
  end

  def health_check(conn, _) do
    conn
  end

  if Mix.env() == :prod do
    defp auth(conn, _opts) do
      username = System.get_env("AUTH_USERNAME", "savvy_flags")
      password = System.get_env("AUTH_PASSWORD", "6iUUG0g5gcrKWSuEbht")
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    end
  else
    defp auth(conn, _opts) do
      conn
    end
  end
end
