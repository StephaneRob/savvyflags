defmodule SavvyFlagsWeb.UI.NavLink do
  use Phoenix.Component
  attr :active, :boolean, default: false
  attr :label, :string, required: true
  attr :navigate, :string, required: true

  def navlink(assigns) do
    ~H"""
    <li class={[
      "rounded hover:bg-emerald-100 hover:text-neutral-700 cursor-pointer relative",
      if(@active,
        do: "bg-emerald-100 text-emerald-800 font-bold"
      )
    ]}>
      <.link navigate={@navigate} class="px-2 py-1  inline-block w-full">
        {@label}
      </.link>
    </li>
    """
  end
end
