defmodule SavvyFlags.SdkConnections do
  import Ecto.Query, warn: false

  alias SavvyFlags.Repo
  alias SavvyFlags.Projects
  alias SavvyFlags.SdkConnections.{SdkConnection, SdkConnectionRequest}

  def list_sdk_connections_for_feature(feature) do
    query =
      from s in SdkConnection,
        join: p in assoc(s, :projects),
        where: p.id == ^feature.project_id,
        order_by: [asc: s.inserted_at]

    Repo.all(query)
  end

  def list_sdk_connections(preloads) do
    list_sdk_connections()
    |> Repo.preload(preloads)
  end

  def list_sdk_connections do
    query =
      from sdk in SdkConnection,
        order_by: [asc: sdk.inserted_at]

    Repo.all(query)
  end

  def get_sdk_connection!(reference) do
    Repo.get_by!(SdkConnection, reference: reference)
    |> Repo.preload([:projects, :environment])
  end

  def get_sdk_connection_by_reference!(reference) do
    get_sdk_connection!(reference)
  end

  def get_sdk_connection(reference) do
    SdkConnection
    |> Repo.get_by(reference: reference)
  end

  def update_sdk_connection(sdk_connection, attrs) do
    projects =
      get_by_atom_or_string(attrs, :project_ids, [])
      |> Enum.map(&Projects.get_project!(&1))

    sdk_connection
    |> SdkConnection.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:projects, projects)
    |> Repo.update()
  end

  def create_sdk_connection(attrs) do
    projects =
      get_by_atom_or_string(attrs, :project_ids, [])
      |> Enum.map(&Projects.get_project!(&1))

    %SdkConnection{}
    |> SdkConnection.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:projects, projects)
    |> Repo.insert()
  end

  def delete_sdk_connection(sdk_connection) do
    Repo.delete(sdk_connection)
  end

  def get_by_atom_or_string(map, attr, default \\ nil) do
    Map.get(map, attr, Map.get(map, "#{attr}", default))
  end

  def change_sdk_connection(%SdkConnection{} = sdk_connection, attrs \\ %{}) do
    # projects =
    # get_by_atom_or_string(attrs, :project_ids, [])
    # |> Enum.map(&get_project!(&1))

    SdkConnection.changeset(sdk_connection, attrs)
    # |> Ecto.Changeset.put_assoc(:projects, projects)
  end

  def incr_requests(sdk_connection_id) do
    q =
      from sdkr in SdkConnectionRequest,
        update: [inc: [count: 1]],
        where:
          sdkr.sdk_connection_id == ^sdk_connection_id and sdkr.inserted_at > ago(5, "minute")

    case Repo.update_all(q, []) do
      {0, _} ->
        create_sdk_connection_request(sdk_connection_id)

      _ ->
        :ok
    end
  end

  def create_sdk_connection_request(sdk_connection_id) do
    %SdkConnectionRequest{
      sdk_connection_id: sdk_connection_id,
      count: 1
    }
    |> Repo.insert!()
  end

  def generate_series(sdk_connection_id, num_days) do
    sql = """
      select
        cast(calendar.entry as date) as date_str,
        coalesce(sum(sdk_connection_requests.count), 0)
      from
        generate_series(now(), now() - $2::integer * interval '1 day', '-1 day') as calendar (entry)
        left join sdk_connection_requests on sdk_connection_requests.sdk_connection_id = $1::integer
          and cast(sdk_connection_requests.inserted_at as date) = cast(calendar.entry as date)
      group by calendar.entry
      order by date_str asc
    """

    Repo.query!(sql, [sdk_connection_id, Enum.max([0, num_days - 1])])
    |> Map.fetch!(:rows)
  end
end
