defmodule SavvyFlagsWeb.Router.Features do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/features/:reference/edit", FeatureLive.Index, :edit
      live "/features/new", FeatureLive.Index, :new

      live "/features/:reference/environments/:environment/rules/new",
           FeatureLive.Show,
           :fr_new

      live "/features/:reference/environments/:environment/rules/:rule",
           FeatureLive.Show,
           :fr_edit

      live "/features/:reference/environments/:environment",
           FeatureLive.Show,
           :environment

      live "/features/:reference/rules/new", FeatureLive.Show, :rule
      live "/features/:reference", FeatureLive.Show, :show
      live "/features", FeatureLive.Index, :index
    end
  end
end
