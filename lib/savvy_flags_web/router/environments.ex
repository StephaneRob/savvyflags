defmodule SavvyFlagsWeb.Router.Environments do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/environments/:reference/edit",
           EnvironmentLive.Index,
           :edit

      live "/environments/new",
           EnvironmentLive.Index,
           :new

      live "/environments", EnvironmentLive.Index, :index
    end
  end
end
