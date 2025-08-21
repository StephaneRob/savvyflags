defmodule SavvyFlags.Repo.Migrations.CreateFeatures do
  use Ecto.Migration

  def change do
    create table(:features) do
      add :reference, :string, null: false
      add :key, :string, null: false
      add :description, :text
      add :default_value, :jsonb
      add :project_id, references(:projects, on_delete: :delete_all)
      add :environments_enabled, {:array, :integer}, default: []
      add :archived_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:features, [:key])
    create unique_index(:features, [:reference])

    create table(:feature_rules) do
      add :reference, :string, null: false
      add :position, :integer, null: false
      add :scheduled_at, :utc_datetime
      add :scheduled, :boolean, null: false, default: false
      add :activated_at, :utc_datetime
      add :description, :text
      add :value, :jsonb
      add :feature_id, references(:features, on_delete: :delete_all), null: false
      add :environment_id, references(:environments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feature_rules, [:reference])

    create table(:feature_rule_conditions) do
      add :position, :integer, null: false
      add :reference, :string, null: false
      add :value, :jsonb
      add :feature_rule_id, references(:feature_rules, on_delete: :delete_all), null: false
      add :attribute_id, references(:attributes, on_delete: :delete_all), null: false
      add :type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feature_rule_conditions, [:reference])

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
