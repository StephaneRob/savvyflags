defmodule SavvyFlags.SdkConnections.SdkConnectionStatsTest do
  use SavvyFlags.DataCase, async: false
  import SavvyFlags.SdkConnectionsFixtures

  setup do
    start_supervised!(SavvyFlags.SdkConnections.SdkConnectionStats)
    environment = SavvyFlags.EnvironmentsFixtures.environment_fixture()
    project = SavvyFlags.ProjectsFixtures.project_fixture()

    sdk_connection =
      sdk_connection_fixture(%{
        name: "Production / Global",
        project_ids: [project.id],
        environment_id: environment.id
      })

    %{sdk_connection: sdk_connection}
  end

  test "should create a sdk connection request when receiving temetry event", %{
    sdk_connection: sdk_connection
  } do
    :telemetry.execute([:sdk_connection, :start], %{}, %{
      sdk_connection_id: sdk_connection.id
    })
  end
end
