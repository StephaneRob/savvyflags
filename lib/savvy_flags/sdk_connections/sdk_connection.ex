defmodule SavvyFlags.SdkConnections.SdkConnection do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "sdk_connections" do
    field :name, :string
    field :description, :string
    prefixed_reference :sdk_connection
    belongs_to :environment, SavvyFlags.Environments.Environment

    many_to_many :projects, SavvyFlags.Projects.Project,
      join_through: "sdk_connection_projects",
      on_replace: :delete

    field :project_ids, {:array, :integer}, virtual: true
    field :mode, Ecto.Enum, values: [:plain, :remote_evaluated], default: :plain
    has_many :sdk_connection_requests, SavvyFlags.SdkConnections.SdkConnectionRequest
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sdk_connection, attrs) do
    sdk_connection
    |> cast(attrs, [:name, :description, :environment_id, :mode, :project_ids])
    |> validate_length(:description, max: 150)
    |> validate_required([:name])
  end

  def mode(mode) do
    modes()[mode]
  end

  def modes do
    %{
      remote_evaluated: "Remote Evaluated",
      plain: "Plain"
    }
  end
end
