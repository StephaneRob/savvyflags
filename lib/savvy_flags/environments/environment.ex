defmodule SavvyFlags.Environments.Environment do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "environments" do
    field :name, :string
    field :color, :string
    field :description, :string
    prefixed_reference :environment
    has_many :feature_rules, SavvyFlags.Features.FeatureRule

    many_to_many :sdk_connections, SavvyFlags.SdkConnections.SdkConnection,
      join_through: "sdk_connection_environments"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attribute, attrs) do
    attribute
    |> cast(attrs, [:name, :description, :color])
    |> validate_length(:description, max: 150)
    |> validate_required([:name])
    |> set_color()
  end

  def set_color(changeset) do
    if get_field(changeset, :color) do
      changeset
    else
      put_change(changeset, :color, "##{random_color()}")
    end
  end

  def default_environments do
    [
      %{name: "production", color: "#ef4444", description: "Do not deploy on Friday!"},
      %{name: "staging", color: "#22c55e", description: "Testing, it's doubting (◔_◔)"}
    ]
  end

  def random_color do
    random = :crypto.strong_rand_bytes(32)

    :md5
    |> :crypto.hash(random)
    |> Base.encode16()
    |> String.slice(0..5)
  end

  def prefix do
    SavvyFlags.PrefixedId.prefix(:environment)
  end
end
