defmodule SavvyFlagsWeb.UI.Breadcrumb do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext
  import SavvyFlagsWeb.UI.Icon

  slot :items
  slot :actions
  attr :class, :string, default: nil
  slot :subtitle

  def breadcrumb(assigns) do
    assigns = %{assigns | items: Enum.with_index(assigns.items)}

    ~H"""
    <div class="mb-5">
      <div class={["flex justify-between items-center h-10", @class]}>
        <ol class="inline-flex items-center space-x-1 md:space-x-2 rtl:space-x-reverse">
          <li :for={{item, idx} <- @items} class="inline-flex items-center">
            <%= if idx > 0 do %>
              <.icon name="hero-chevron-right" class="w-3 h-3 text-gray-400 mr-1" />
            <% end %>
            <span class={if idx + 1 < length(@items), do: "font-bold ", else: "font-semibold"}>
              {render_slot(item)}
            </span>
          </li>
        </ol>
        <div class="flex-none">{render_slot(@actions)}</div>
      </div>
      <p class="text-gray-600 text-sm italic">{render_slot(@subtitle)}</p>
    </div>
    """
  end
end
