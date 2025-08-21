defmodule SavvyFlags.SdkConnectionsFixtures do
  def sdk_connection_fixture(attrs \\ %{}) do
    {:ok, sdk_connection} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> SavvyFlags.SdkConnections.create_sdk_connection()

    sdk_connection
  end
end
