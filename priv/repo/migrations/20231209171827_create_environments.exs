defmodule SavvyFlags.Repo.Migrations.CreateEnvironments do
  use Ecto.Migration

  def change do
    create table(:environments) do
      add :reference, :string, null: false
      add :name, :string, null: false
      add :color, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:environments, [:reference])
    create unique_index(:environments, [:name])
  end
end
