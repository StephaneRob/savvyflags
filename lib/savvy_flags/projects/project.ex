defmodule SavvyFlags.Projects.Project do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "projects" do
    field :name, :string
    field :description, :string
    prefixed_reference :project

    many_to_many :sdk_connections, SavvyFlags.SdkConnections.SdkConnection,
      join_through: "sdk_connection_projects"

    many_to_many :users, SavvyFlags.Accounts.User, join_through: "user_projects"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attribute, attrs) do
    attribute
    |> cast(attrs, [:name, :description])
    |> validate_length(:description, max: 150)
    |> validate_required([:name])
  end

  def default_projects do
    [
      %{name: "Default", description: "Default project where your feature flags belongs to"}
    ]
  end

  def prefix do
    SavvyFlags.PrefixedId.prefix(:project)
  end
end
