defmodule SavvyFlagsWeb.Search do
  use SavvyFlagsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="relative" phx-hook="Search" id={@id}>
      <div class="relative">
        <.search_input
          multiple={@multiple}
          myself={@myself}
          items={@items}
          search_value={@search_value}
        />
        <.search_results
          multiple={@multiple}
          results={@results}
          myself={@myself}
          field={@field}
          open={@open}
        />
      </div>
      <.search_items myself={@myself} field={@field} />
      <.search_field field={@field} />
    </div>
    """
  end

  def search_field(assigns) do
    ~H"""
    <.input field={@field} type="hidden" />
    """
  end

  def search_items(assigns) do
    ~H"""
    <div class="flex items-center flex-wrap mt-2">
      <.tag :for={item <- String.split(@field.value || "", ",", trim: true)} class="mr-2 mb-2">
        {item}
        <:close>
          <button
            type="button"
            phx-click="remove-item"
            phx-target={@myself}
            phx-value-item={item}
            class="m-0 p-0 border-0 bg-transparent"
          >
            <.icon name="hero-x-mark-solid" class="h-4 w-4" />
          </button>
        </:close>
      </.tag>
    </div>
    """
  end

  def search_input(assigns) do
    ~H"""
    <.input
      type="text"
      name="search"
      value={@search_value}
      phx-change="input"
      phx-keyup="keyup"
      phx-target={@myself}
      disabled={!@multiple and length(@items) > 0}
    />
    """
  end

  def search_results(assigns) do
    ~H"""
    <div
      :if={@open && length(@results) > 0}
      class="search-results absolute top-full mt-1 max-h-40 border border-gray-200 rounded w-full bg-white overflow-y-scroll z-50"
    >
      <div
        :for={%{"name" => name, "value" => value} <- @results}
        class="px-2 py-1 odd:bg-gray-50 hover:bg-gray-100 cursor-pointer"
        phx-click="add-item"
        phx-value-item={value}
        phx-target={@myself}
      >
        <%= if name do %>
          <span class="text-xs">{name}</span> (<span class="text-xs font-bold"><%= value %></span>)
        <% else %>
          <span class="text-xs font-bold">Add: {value}</span>
        <% end %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    onchange = assigns.onchange
    field = assigns.field
    results = onchange.("") || []

    items =
      String.split(field.value || "", ",", trim: true)

    socket
    |> assign(assigns)
    |> assign(:results, results)
    |> assign(:search_value, "")
    |> assign(:open, false)
    |> assign(:items, items)
    |> ok()
  end

  def handle_event("keyup", %{"key" => "Meta", "value" => value}, socket) do
    items = socket.assigns.items
    items = items ++ [value]

    socket
    |> update(:field, fn field ->
      %{field | value: Enum.join(items, ",")}
    end)
    |> assign(:items, items)
    |> assign(:search_value, "")
    |> noreply()
  end

  def handle_event("keyup", _, socket) do
    noreply(socket)
  end

  def handle_event("input", %{"search" => search}, socket) do
    onchange = socket.assigns.onchange

    results =
      (onchange.(search) || [])
      |> Enum.reject(&is_nil(&1["name"]))
      |> Kernel.++([%{"name" => nil, "value" => search}])

    socket
    |> assign(:open, true)
    |> assign(:results, results)
    |> assign(:search_value, search)
    |> noreply()
  end

  def handle_event("add-item", %{"item" => item}, socket) do
    items = socket.assigns.items
    items = items ++ [item]

    socket
    |> update(:field, fn field ->
      %{field | value: Enum.join(items, ",")}
    end)
    |> assign(:items, items)
    |> assign(:search_value, "")
    |> assign(:open, false)
    |> noreply()
  end

  def handle_event("remove-item", %{"item" => item}, socket) do
    items =
      socket.assigns.items
      |> Enum.reject(&(&1 == item))

    socket
    |> assign(:items, items)
    |> update(:field, fn field ->
      %{field | value: Enum.join(items, ",")}
    end)
    |> noreply()
  end
end
