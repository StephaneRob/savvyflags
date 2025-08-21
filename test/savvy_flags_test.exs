defmodule SavvyFlagsTest do
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Environments
  alias SavvyFlags.Environments.Environment
  alias SavvyFlags.Projects
  alias SavvyFlags.Projects.Project
  alias SavvyFlags.Attributes
  alias SavvyFlags.Attributes.Attribute

  test "setup/0 must create default values" do
    assert Environments.list_environments() == []
    assert Projects.list_projects() == []
    assert Attributes.list_attributes() == []
    SavvyFlags.setup()

    assert [%Environment{name: "production"}, %Environment{name: "staging"}] =
             Environments.list_environments()

    assert [%Project{name: "Default"}] = Projects.list_projects()

    assert [
             %Attribute{name: "id", identifier: true, data_type: :string},
             %Attribute{name: "email", data_type: :string, identifier: true},
             %Attribute{name: "deviceId", data_type: :string, identifier: true},
             %Attribute{name: "loggedIn", data_type: :boolean, identifier: false},
             %Attribute{name: "country", data_type: :string, identifier: false}
           ] = Attributes.list_attributes()
  end
end
