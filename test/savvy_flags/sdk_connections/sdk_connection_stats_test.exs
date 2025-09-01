defmodule SavvyFlags.SdkConnections.SdkConnectionStatsTest do
  use SavvyFlags.DataCase, async: false

  import SavvyFlags.ProjectsFixtures
  import SavvyFlags.FeaturesFixtures
  import SavvyFlags.SdkConnectionsFixtures
  import SavvyFlags.EnvironmentsFixtures

  alias SavvyFlags.Repo
  alias SavvyFlags.Features
  alias SavvyFlags.SdkConnections.SdkConnectionRequest

  setup do
    start_supervised!(SavvyFlags.SdkConnections.SdkConnectionStats)
    :ok
  end

  test "update_stats increments request counter and touches feature last_used_at" do
    environment = environment_fixture()
    project = project_fixture()
    feature = feature_fixture(%{project_id: project.id})

    sdk_connection =
      sdk_connection_fixture(%{
        name: "Production / Global",
        project_ids: [project.id],
        environment_id: environment.id
      })

    meta = %{sdk_connection: sdk_connection, features: [feature.id]}

    SavvyFlags.SdkConnections.SdkConnectionStats.update_stats(meta)
    # allow async cast to complete
    Process.sleep(30)

    # request row created with count 1
    req_query = from r in SdkConnectionRequest, where: r.sdk_connection_id == ^sdk_connection.id
    [row] = Repo.all(req_query)
    assert row.count == 1

    # feature last_used_at touched
    f1 = Features.get_feature!(feature.id) |> Repo.preload(feature_stats: :environment)
    feature_stat = List.first(f1.feature_stats)
    assert feature_stat.last_used_at != nil
    assert feature_stat.environment.id == environment.id
    # calling again within the time window increments the same row
    SavvyFlags.SdkConnections.SdkConnectionStats.update_stats(meta)
    Process.sleep(30)

    row2 = Repo.one(req_query)
    assert row2.count == 2
  end
end
