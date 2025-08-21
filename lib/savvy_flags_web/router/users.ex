defmodule SavvyFlagsWeb.Router.Users do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/users/:reference/edit", UserLive.Index, :edit
      live "/users/new", UserLive.Index, :new
      live "/users", UserLive.Index, :index
    end
  end
end
