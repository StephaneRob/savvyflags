defmodule SavvyFlags.Accounts.PermissionsTest do
  use SavvyFlags.DataCase

  alias SavvyFlags.Accounts.Permissions
  import SavvyFlags.AccountsFixtures

  describe "has_permission?/2" do
    test "returns true when user has the required permission" do
      user = user_fixture(%{project_permissions: 0b0001})
      assert Permissions.has_permission?(user.project_permissions, :read) == true
    end

    test "returns false when user does not have the required permission" do
      user = user_fixture(%{project_permissions: 0b0001})
      assert Permissions.has_permission?(user.project_permissions, :update) == false
    end

    test "returns false when user has no permissions" do
      user = user_fixture(%{project_permissions: 0b0000})
      assert Permissions.has_permission?(user.project_permissions, :read) == false
    end
  end

  describe "humanize_permissions?/2" do
    test "returns [:read] when permission 0b0001" do
      user = user_fixture(%{project_permissions: 0b0001})
      assert Permissions.humanize_permissions(user.project_permissions) == [:read]
    end

    test "returns [:delete, :read] when permission 0b1001" do
      user = user_fixture(%{project_permissions: 0b1001})
      assert Permissions.humanize_permissions(user.project_permissions) == [:delete, :read]
    end
  end
end
