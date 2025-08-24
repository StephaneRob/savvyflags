defmodule SavvyFlagsWeb.UI.Toggle do
  use Phoenix.Component

  attr :label, :string, default: nil
  attr :checked, :boolean, default: false
  attr :id, :string, required: true
  attr :name, :string, required: true

  def toggle(assigns) do
    ~H"""
    <label class="relative inline-flex items-center cursor-pointer text-zinc-800">
      <input type="checkbox" class="sr-only peer" checked={@checked} name={@name} id={@id} />
      <div class="w-9 h-5 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-neutral-300 rounded-sm peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-sm after:h-4 after:w-4 after:transition-all  peer-checked:bg-emerald-400">
      </div>
      <span :if={@label} class="ms-3 text-sm font-medium ">
        {@label}
      </span>
    </label>
    """
  end
end
