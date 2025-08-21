defmodule SavvyFlagsWeb.Router do
  require SavvyFlagsWeb.Router.Features
  require SavvyFlagsWeb.Router.SdkConnections
  require SavvyFlagsWeb.Router.Attributes
  require SavvyFlagsWeb.Router.Users
  require SavvyFlagsWeb.Router.Environments
  require SavvyFlagsWeb.Router.Projects
  use SavvyFlagsWeb, :router

  import SavvyFlagsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SavvyFlagsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :public_api do
    plug :accepts, ["json", "stream"]
    plug CORSPlug, origin: ["http:/localhost:5173"]
  end

  scope "/api", SavvyFlagsWeb do
    pipe_through :public_api

    get "/features/:sdk_connection/stream", Api.FeatureController, :stream
    post "/features/:sdk_connection", Api.FeatureController, :create
    get "/features/:sdk_connection", Api.FeatureController, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:savvy_flags, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SavvyFlagsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes
  scope "/", SavvyFlagsWeb do
    pipe_through [:browser, :require_pre_authenticated_user]

    live_session :require_pre_authenticated_user,
      on_mount: [{SavvyFlagsWeb.UserAuth, :ensure_pre_authenticated}] do
      live "/users/log_in/mfa", UserLoginMfaLive, :new
    end

    post "/users/log_in/mfa", UserSessionController, :mfa
  end

  scope "/", SavvyFlagsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SavvyFlagsWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings/mfa", UserSettings.MfaLive
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end

    scope "/" do
      pipe_through [:check_mfa]

      live_session :require_authenticated_user_and_member,
        on_mount: [
          {SavvyFlagsWeb.UserAuth, :ensure_authenticated},
          {SavvyFlagsWeb.UserAuth, :check_mfa}
        ] do
        SavvyFlagsWeb.Router.Features.routes()
        SavvyFlagsWeb.Router.SdkConnections.routes()
        SavvyFlagsWeb.Router.Projects.routes()
        SavvyFlagsWeb.Router.Environments.routes()
        SavvyFlagsWeb.Router.Attributes.routes()
        SavvyFlagsWeb.Router.Users.routes()

        live "/configuration", ConfigurationLive, :show
        live "/home", HomeLive.Show, :show
      end
    end
  end

  scope "/", SavvyFlagsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SavvyFlagsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/first_run", FirstRunLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    get "/", PageController, :home
  end

  scope "/", SavvyFlagsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SavvyFlagsWeb.UserAuth, :mount_current_user}] do
      live "/users/invitation/:token", UserInvitationLive, :edit
    end
  end
end
