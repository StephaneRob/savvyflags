defmodule SavvyFlags.Application do
  @moduledoc false

  use Application

  case Mix.env() do
    :dev ->
      @other_children [
        SavvyFlags.SdkConnections.SdkConnectionStats,
        SavvyFlags.FeatureRulesActivator,
        {Bandit, plug: SavvyFlags.MockAttributes, port: 4001}
      ]

    :prod ->
      @other_children [
        SavvyFlags.SdkConnections.SdkConnectionStats,
        SavvyFlags.FeatureRulesActivator
      ]

    :test ->
      @other_children []
  end

  @impl true
  def start(_type, _args) do
    children =
      [
        SavvyFlagsWeb.Telemetry,
        SavvyFlags.Repo,
        {DNSCluster, query: Application.get_env(:savvy_flags, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: SavvyFlags.PubSub},
        {Finch, name: SavvyFlags.Finch},
        {Cachex, name: SavvyFlags.FeatureCache},
        SavvyFlagsWeb.Endpoint
      ] ++ @other_children

    opts = [strategy: :one_for_one, name: SavvyFlags.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SavvyFlagsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
