defmodule SavvyFlags.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :mfa_required, :boolean, default: false
      add :feature_key_format, :string
      add :stale_threshold, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
