defmodule SavvyFlagsWeb.UI.Breadcrumb do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext

  slot :items
  slot :actions
  attr :class, :string, default: nil
  slot :subtitle

  def breadcrumb(assigns) do
    assigns = %{assigns | items: Enum.with_index(assigns.items)}

    ~H"""
    <div class="mb-10">
      <div class={["flex justify-between items-center h-10", @class]}>
        <ol class="inline-flex items-center space-x-1 md:space-x-2 rtl:space-x-reverse">
          <li :for={{item, idx} <- @items} class="inline-flex items-center">
            <%= if idx > 0 do %>
              <svg
                class="rtl:rotate-180 w-3 h-3 text-gray-400 mx-1"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 6 10"
              >
                <path
                  stroke="currentColor"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="m1 9 4-4-4-4"
                />
              </svg>
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
