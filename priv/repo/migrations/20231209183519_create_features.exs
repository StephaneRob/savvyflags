defmodule SavvyFlags.Repo.Migrations.CreateFeatures do
  use Ecto.Migration

  def change do
    create table(:features) do
      add :reference, :string, null: false
      add :key, :string, null: false
      add :description, :text
      add :project_id, references(:projects, on_delete: :delete_all)
      add :environments_enabled, {:array, :integer}, default: []
      add :archived_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:features, [:key])
    create unique_index(:features, [:reference])

    create table(:feature_revisions) do
      add :feature_id, references(:features, on_delete: :delete_all), null: false
      add :revision_number, :integer, null: false
      add :status, :string, null: false, default: "draft"
      add :created_by_id, references(:users, on_delete: :delete_all), null: false
      add :updated_by_id, references(:users, on_delete: :delete_all), null: false
      add :value, :jsonb, default: "{}"

      timestamps()
    end

    create unique_index(:feature_revisions, [:feature_id, :revision_number])
    create index(:feature_revisions, [:feature_id])

    create table(:feature_stats) do
      add :feature_id, references(:features, on_delete: :delete_all), null: false
      add :environment_id, references(:environments, on_delete: :delete_all), null: false
      add :first_used_at, :utc_datetime
      add :last_used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feature_stats, [:feature_id, :environment_id])

    create table(:feature_rules) do
      add :reference, :string, null: false
      add :position, :integer, null: false
      add :scheduled_at, :utc_datetime
      add :scheduled, :boolean, null: false, default: false
      add :activated_at, :utc_datetime
      add :description, :text
      add :value, :jsonb
      add :conditions, {:array, :map}, default: []

      add :feature_revision_id, references(:feature_revisions, on_delete: :delete_all),
        null: false

      add :environment_id, references(:environments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feature_rules, [:reference])

    create table(:user_features, primary_key: false) do
      add :user_id, references(:users)
      add :feature_id, references(:features)
    end

    create table(:user_projects, primary_key: false) do
      add :user_id, references(:users)
      add :project_id, references(:projects)
    end

    create table(:user_environments, primary_key: false) do
      add :user_id, references(:users)
      add :environment_id, references(:environments)
    end

    alter table(:users) do
      add :environment_permissions, :integer, default: 0
      add :project_permissions, :integer, default: 0
      add :attribute_permissions, :integer, default: 0
      add :sdk_connection_permissions, :integer, default: 0
    end
  end
end
