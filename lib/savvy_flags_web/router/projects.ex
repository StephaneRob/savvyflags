defmodule SavvyFlagsWeb.Router.Projects do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/projects/:reference/edit",
           ProjectLive.Index,
           :edit

      live "/projects/new",
           ProjectLive.Index,
           :new

      live "/projects", ProjectLive.Index, :index
    end
  end
end
