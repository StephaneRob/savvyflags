defmodule SavvyFlags.AttributesFixtures do
  def attribute_fixture(attrs \\ %{}) do
    {:ok, attribute} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> SavvyFlags.Attributes.create_attribute()

    attribute
  end
end
