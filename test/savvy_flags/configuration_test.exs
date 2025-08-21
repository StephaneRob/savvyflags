defmodule SavvyFlags.ConfigurationTest do
  use SavvyFlags.DataCase, async: true

  describe "init/1" do
    test "must create a configuration with default values" do
      assert {:ok, configuration} = SavvyFlags.Configurations.init()
      refute configuration.mfa_required
      assert configuration.feature_custom_format == nil
    end
  end

  describe "update/1" do
    test "must update a configuration" do
      attrs = %{mfa_required: true}
      assert {:ok, configuration} = SavvyFlags.Configurations.init()

      assert {:ok, configuration} =
               SavvyFlags.Configurations.update_configuration(configuration, attrs)

      assert configuration.mfa_required
    end
  end

  describe "change_configuration/1" do
    test "must return configuration changeset" do
      attrs = %{mfa_required: true}
      assert {:ok, configuration} = SavvyFlags.Configurations.init()

      assert %Ecto.Changeset{} =
               changeset =
               SavvyFlags.Configurations.change_configuration(configuration, attrs)

      assert get_change(changeset, :mfa_required)
    end
  end
end
