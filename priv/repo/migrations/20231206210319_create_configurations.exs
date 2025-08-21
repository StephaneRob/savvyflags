defmodule SavvyFlags.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :mfa_required, :boolean, default: false
      add :feature_custom_format, :string

      timestamps(type: :utc_datetime)
    end
  end
end
