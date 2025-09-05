defmodule SavvyFlagsWeb.ActiveNav do
  alias Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, LiveView.attach_hook(socket, :active_nav, :handle_params, &set_active_nav/3)}
  end

  defp set_active_nav(_, _url, socket) do
    view = to_string(socket.view)

    active_nav =
      case {view, socket.assigns.live_action} do
        {"Elixir.SavvyFlagsWeb.FeatureLive." <> _, _} -> :features
        {"Elixir.SavvyFlagsWeb.AttributeLive." <> _, _} -> :attributes
        {"Elixir.SavvyFlagsWeb.EnvironmentLive." <> _, _} -> :environments
        {"Elixir.SavvyFlagsWeb.ProjectLive." <> _, _} -> :projects
        {"Elixir.SavvyFlagsWeb.SdkConnectionLive." <> _, _} -> :sdk_connections
        {"Elixir.SavvyFlagsWeb.UserLive." <> _, _} -> :users
        {"Elixir.SavvyFlagsWeb.ConfigurationLive" <> _, _} -> :configuration
        _ -> nil
      end

    {:cont, Phoenix.Component.assign(socket, active_nav: active_nav)}
  end
end
