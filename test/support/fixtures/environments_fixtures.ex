defmodule SavvyFlags.EnvironmentsFixtures do
  def environment_fixture(attrs \\ %{}) do
    {:ok, environment} =
      attrs
      |> Enum.into(%{
        name: "some-#{System.unique_integer()}"
      })
      |> SavvyFlags.Environments.create_environment()

    environment
  end
end
