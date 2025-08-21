defmodule SavvyFlags.ProjectsFixtures do
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "some-#{System.unique_integer()}"
      })
      |> SavvyFlags.Projects.create_project()

    project
  end
end
