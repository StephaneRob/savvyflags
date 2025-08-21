defmodule SavvyFlags.Repo.Migrations.CreateAttributes do
  use Ecto.Migration

  def change do
    create table(:attributes) do
      add :reference, :string, null: false
      add :name, :string, null: false
      add :data_type, :string, null: false
      add :identifier, :boolean, default: false
      add :description, :string
      add :remote, :boolean, default: false
      add :url, :string
      add :access_token, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:attributes, [:reference])
  end
end
