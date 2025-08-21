defmodule SavvyFlags.Fields do
  import Ecto.Schema, only: [field: 3]

  defmacro prefixed_reference(object) do
    quote do
      field :reference, :string,
        autogenerate: {SavvyFlags.PrefixedId, :generate, [unquote(object)]}
    end
  end
end
