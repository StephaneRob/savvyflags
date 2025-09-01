defmodule SavvyFlags.Configurations do
  import Ecto.Query, warn: false
  alias SavvyFlags.Repo
  alias SavvyFlags.Configurations.Configuration

  def init do
    %Configuration{}
    |> Configuration.changeset(%{})
    |> Repo.insert()
  end

  def get_configuration do
    Repo.one(Configuration)
  end

  def update_configuration(configuration, attrs) do
    configuration
    |> Configuration.changeset(attrs)
    |> Repo.update()
  end

  def change_configuration(%Configuration{} = configuration, attrs \\ %{}) do
    Configuration.changeset(configuration, attrs)
  end

  @stale_threshold 30

  def stale_threshold do
    get_configuration().stale_threshold || @stale_threshold
  end
end
