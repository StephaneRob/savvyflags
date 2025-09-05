defmodule SavvyFlags.Features.Revision do
  use Ecto.Schema
  import Ecto.Changeset
  alias SavvyFlags.Features.FeatureValue

  schema "feature_revisions" do
    field :revision_number, :integer, default: 1
    field :status, Ecto.Enum, values: [:draft, :published, :unpublished], default: :draft

    embeds_one :value, FeatureValue, on_replace: :delete

    belongs_to :feature, SavvyFlags.Features.Feature
    belongs_to :created_by, SavvyFlags.Accounts.User
    belongs_to :updated_by, SavvyFlags.Accounts.User

    has_many :rules, SavvyFlags.Features.Rule,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :environments, through: [:rules, :environment]

    timestamps(type: :utc_datetime)
  end

  def changeset(revision, attrs) do
    revision
    |> cast(attrs, [:feature_id, :revision_number, :created_by_id, :updated_by_id, :status])
    |> cast_embed(:value, with: &FeatureValue.changeset/2)
    |> validate_required([:revision_number, :created_by_id, :updated_by_id])
  end
end
