defmodule SavvyFlagsWeb.Router.Attributes do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/attributes/:reference/edit",
           AttributeLive.Index,
           :edit

      live "/attributes/new",
           AttributeLive.Index,
           :new

      live "/attributes", AttributeLive.Index, :index
    end
  end
end
