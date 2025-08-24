defmodule SavvyFlagsWeb.UI.Check do
  use Phoenix.Component
  import SavvyFlagsWeb.UI.Icon

  attr :value, :boolean, default: false

  def check(assigns) do
    ~H"""
    <%= if @value do %>
      <.icon name="hero-check-circle-solid" class="ml-1 h-5 w-5 text-green-500" />
    <% else %>
      <.icon name="hero-x-circle-solid" class="ml-1 h-5 w-5 text-red-500" />
    <% end %>
    """
  end
end
