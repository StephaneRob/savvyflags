defmodule SavvyFlagsWeb.UI.Dropdown do
  use Phoenix.Component
  import SavvyFlagsWeb.UI.Button
  import SavvyFlagsWeb.UIHelpers

  attr :id, :string, required: true
  slot :dropdown_button, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <div class="dropdown relative inline-block text-left" id={@id}>
      <.button variant="ghost" phx-click={show("##{@id}-container")} size="sm">
        {render_slot(@dropdown_button)}
      </.button>
      <.focus_wrap
        id={"#{@id}-container"}
        phx-window-keydown={hide("##{@id}-container")}
        phx-key="escape"
        phx-click-away={hide("##{@id}-container")}
        class="shadow-zinc-800/10 ring-zinc-700/10 absolute right-0 origin-top-left hidden rounded bg-white shadow-md transition mt-1 z-50 border border-neutral-200"
      >
        {render_slot(@inner_block)}
      </.focus_wrap>
    </div>
    """
  end

  slot :inner_block, required: true

  def dropdown_item(assigns) do
    ~H"""
    <div class="dropdown-item gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 cursor-pointer inline-flex flex-1">
      {render_slot(@inner_block)}
    </div>
    """
  end
end
