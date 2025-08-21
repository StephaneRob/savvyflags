defmodule SavvyFlagsWeb.SelectMultiple do
  use SavvyFlagsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={["mt-2 relative select-multiple", @open]}>
      <.label>{@label}</.label>
      <div
        class="relative border cursor-pointer border-zinc-300 focus:border-zinc-400 w-full rounded-sm h-10 flex items-center px-2 py-1.5"
        phx-click="toggle-dropdown"
        phx-target={@myself}
      >
        <.icon
          name="hero-chevron-down"
          class="text-zinc-400 h-3 w-3 absolute top-1/2 right-4 -translate-y-1/2"
        />

        <.tag :for={{name, id} <- @values} class="mr-2">
          {name}
          <:close>
            <button
              type="button"
              phx-click="remove-item"
              phx-target={@myself}
              value={id}
              class="m-0 p-0 border-0 bg-transparent"
            >
              <.icon name="hero-x-mark-solid" class="h-4 w-4" />
            </button>
          </:close>
        </.tag>
        <span :if={@prompt} class="text-sm text-neutral-600">{@prompt}</span>
      </div>
      <div class="absolute z-50 shadow-sm w-full mt-2 bg-white select-multiple-values border cursor-pointer border-zinc-300 focus:border-zinc-400">
        <ul>
          <li
            :for={{name, id} <- @displayed_options}
            class="px-2 py-1.5 text-sm hover:bg-neutral-200 select-multiple-value"
            value={id}
            phx-click="add-item"
            phx-target={@myself}
          >
            {name}
          </li>
          <li
            :if={length(@displayed_options) == 0}
            class="px-2 py-1.5 text-sm cursor-not-allowed select-multiple-value italic"
          >
            No results
          </li>
        </ul>
      </div>

      <.input
        invisible={true}
        type="select"
        options={Enum.map(@options, &elem(&1, 1))}
        multiple
        field={@field}
        class="select-form-value"
        phx-hook="SelectMultiple"
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    values = values(assigns.options, assigns.field.value)
    displayed_options = options(assigns.options, values)

    socket
    |> assign(assigns)
    |> assign(:displayed_options, displayed_options)
    |> assign(:values, values)
    |> assign(:open, "")
    |> ok()
  end

  def handle_event("add-item", %{"value" => id}, socket) do
    add_value = Enum.find(socket.assigns.options, &(elem(&1, 1) == id))
    old_values = socket.assigns.values
    values = old_values ++ [add_value]

    socket
    |> assign(:field, %{socket.assigns.field | value: Enum.map(values, &elem(&1, 1))})
    |> assign(:values, values)
    |> assign(:displayed_options, options(socket.assigns.options, values))
    |> noreply()
  end

  @impl true
  def handle_event("remove-item", %{"value" => id}, socket) when is_binary(id) do
    id = String.to_integer(id)
    handle_event("remove-item", %{"value" => id}, socket)
  end

  @impl true
  def handle_event("remove-item", %{"value" => id}, socket) do
    values = Enum.reject(socket.assigns.values, &(elem(&1, 1) == id))

    socket
    |> assign(:field, %{socket.assigns.field | value: Enum.map(values, &elem(&1, 1))})
    |> assign(:values, values)
    |> assign(:displayed_options, options(socket.assigns.options, values))
    |> noreply()
  end

  @impl true
  def handle_event("toggle-dropdown", _, socket) do
    value = if socket.assigns.open == "open", do: "", else: "open"

    socket
    |> assign(:open, value)
    |> noreply()
  end

  defp options(options, value) do
    Enum.reject(options, &(&1 in value))
    |> Enum.sort_by(&elem(&1, 1))
  end

  defp values(options, nil) do
    values(options, [])
  end

  defp values(options, value) do
    Enum.filter(options, &(to_string(elem(&1, 1)) in value or elem(&1, 1) in value))
    |> Enum.sort_by(&elem(&1, 1))
  end
end
