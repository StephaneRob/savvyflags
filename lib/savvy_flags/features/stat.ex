defmodule SavvyFlags.Features.Stat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feature_stats" do
    belongs_to :feature, SavvyFlags.Features.Feature
    belongs_to :environment, SavvyFlags.Environments.Environment
    field :first_used_at, :utc_datetime
    field :last_used_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(stat, attrs) do
    stat
    |> cast(attrs, [:feature_id, :environment_id, :first_used_at, :last_used_at])
    |> validate_required([:feature_id, :environment_id])
  end
end
