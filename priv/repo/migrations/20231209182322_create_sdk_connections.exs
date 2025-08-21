defmodule SavvyFlags.Repo.Migrations.CreateSdkConnections do
  use Ecto.Migration

  def change do
    create table(:sdk_connections) do
      add :reference, :string, null: false
      add :name, :string, null: false
      add :description, :string
      add :environment_id, references(:environments, on_delete: :delete_all), null: false
      add :mode, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sdk_connections, [:reference])

    create table(:sdk_connection_projects, primary_key: false) do
      add :sdk_connection_id, references(:sdk_connections)
      add :project_id, references(:projects)
    end

    create table(:sdk_connection_requests) do
      add :count, :integer, default: 0
      add :sdk_connection_id, references(:sdk_connections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
