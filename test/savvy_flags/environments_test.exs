defmodule SavvyFlags.EnvironmentsTest do
  use SavvyFlags.DataCase, async: true
  import SavvyFlags.EnvironmentsFixtures
  alias SavvyFlags.Environments
  alias SavvyFlags.Environments.Environment

  setup do
    environment = environment_fixture()
    %{environment: environment}
  end

  describe "get_environment_by_id!/1" do
    test "return an environment if id exists", %{environment: environment} do
      assert %Environment{} = env = Environments.get_environment_by_id!(environment.id)
      assert environment.id == env.id
    end

    test "raise if environment doesn't exists" do
      assert_raise Ecto.NoResultsError, fn ->
        Environments.get_environment_by_id!(-1)
      end
    end
  end
end
