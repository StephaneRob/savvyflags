defmodule SavvyFlags.Projects do
  import Ecto.Query, warn: false

  alias SavvyFlags.Repo
  alias SavvyFlags.Projects.Project

  def list_projects(preloads) do
    list_projects()
    |> Repo.preload(preloads)
  end

  def list_projects do
    Repo.all(Project)
  end

  def get_project_by_reference!(reference) do
    Repo.get_by!(Project, reference: reference)
  end

  def get_project!(id) do
    Repo.get!(Project, id)
  end

  def update_project(project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end
end
