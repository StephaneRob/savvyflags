defmodule SavvyFlagsWeb.Router.SdkConnections do
  import Phoenix.LiveView.Router

  defmacro routes do
    quote do
      live "/sdk-connections/:reference/edit",
           SdkConnectionLive.Index,
           :edit

      live "/sdk-connections/new",
           SdkConnectionLive.Index,
           :new

      live "/sdk-connections/:reference/metrics",
           SdkConnectionLive.Show,
           :metrics

      live "/sdk-connections/:reference/sandbox",
           SdkConnectionLive.Show,
           :sandbox

      live "/sdk-connections/:reference",
           SdkConnectionLive.Show,
           :show

      live "/sdk-connections", SdkConnectionLive.Index, :index
    end
  end
end
