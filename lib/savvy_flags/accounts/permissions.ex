defmodule SavvyFlags.Accounts.Permissions do
  import Bitwise

  @crud_permissions %{
    read: 0b0001,
    create: 0b0010,
    update: 0b0100,
    delete: 0b1000
  }

  def has_permission?(permissions, permission) do
    (permissions &&& @crud_permissions[permission]) != 0
  end

  def grant_permission(current_permissions, permission) do
    current_permissions ||| @crud_permissions[permission]
  end

  def revoke_permission(current_permissions, permission) do
    current_permissions &&& bnot(@crud_permissions[permission])
  end

  def has_permissions?(permissions, required_permissions) do
    mask =
      required_permissions
      |> Enum.map(&@crud_permissions[&1])
      |> Enum.reduce(0, &(&1 ||| &2))

    (permissions &&& mask) == mask
  end

  def build_permissions(user) do
    Enum.into([:attribute, :project, :environment], %{}, fn attr ->
      {attr,
       Enum.into([:read, :create, :update, :delete], %{}, fn action ->
         {action, has_permission?(Map.get(user, :"#{attr}_permissions", 0), action)}
       end)}
    end)
  end

  def humanize_permissions(permissions) do
    Map.keys(@crud_permissions)
    |> Enum.map(fn action ->
      if has_permission?(permissions, action) do
        action
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
