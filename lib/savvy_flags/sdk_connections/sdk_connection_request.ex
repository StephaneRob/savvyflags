defmodule SavvyFlags.SdkConnections.SdkConnectionRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sdk_connection_requests" do
    field :count, :integer
    belongs_to :sdk_connection, SavvyFlags.SdkConnections.SdkConnection
    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(sdk_connection, attrs) do
    sdk_connection
    |> cast(attrs, [:count])
    |> validate_required([:count])
  end
end
