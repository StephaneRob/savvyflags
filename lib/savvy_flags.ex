defmodule SavvyFlags do
  @moduledoc """
  SavvyFlags keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def setup do
    SavvyFlags.Configurations.init()

    attributes =
      SavvyFlags.Utils.build_defaults(
        SavvyFlags.Attributes.Attribute.default_attributes(),
        :attribute
      )

    SavvyFlags.Repo.insert_all(SavvyFlags.Attributes.Attribute, attributes)

    environments =
      SavvyFlags.Utils.build_defaults(
        SavvyFlags.Environments.Environment.default_environments(),
        :environment
      )

    SavvyFlags.Repo.insert_all(SavvyFlags.Environments.Environment, environments)

    projects =
      SavvyFlags.Utils.build_defaults(SavvyFlags.Projects.Project.default_projects(), :project)

    SavvyFlags.Repo.insert_all(SavvyFlags.Projects.Project, projects)
  end

  def version do
    Application.spec(:savvy_flags, :vsn)
  end
end
