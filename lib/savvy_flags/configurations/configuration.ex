defmodule SavvyFlags.Configurations.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "configurations" do
    field :mfa_required, :boolean
    field :feature_key_format, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:mfa_required, :feature_key_format])
  end
end
