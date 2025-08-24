defmodule SavvyFlagsWeb.UI.NavLink do
  use Phoenix.Component
  attr :active, :boolean, default: false
  attr :label, :string, required: true
  attr :navigate, :string, required: true

  def navlink(assigns) do
    ~H"""
    <li class={[
      "py-1 rounded hover:bg-neutral-100 hover:text-neutral-700 cursor-pointer relative",
      if(@active,
        do: "bg-neutral-100 text-neutral-700 font-bold"
      )
    ]}>
      <.link navigate={@navigate} class="px-5 inline-block w-full">
        {@label}
      </.link>
    </li>
    """
  end
end
