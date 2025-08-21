defmodule SavvyFlags.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :reference, :string, null: false
      add :name, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:projects, [:reference])
    create unique_index(:projects, [:name])
  end
end
