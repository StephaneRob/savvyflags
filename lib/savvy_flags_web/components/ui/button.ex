defmodule SavvyFlagsWeb.UI.Button do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :variant, :string, default: "primary"
  attr :size, :string, default: "lg"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={
        Tails.classes([
          "phx-submit-loading:opacity-75 rounded",
          "rounded-full px-4 text-sm py-2 cursor-pointer",
          variant(@variant),
          size(@size),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp size(size) do
    case size do
      "lg" -> "py-1.5 px-4"
      "sm" -> "py-0.5 px-3 text-xs"
    end
  end

  defp variant(variant) do
    case variant do
      "primary" ->
        "bg-neutral-900 border border-black text-white hover:bg-black"

      "secondary" ->
        "bg-white border text-black hover:bg-neutral-100"

      "danger" ->
        "bg-red-300 hover:bg-red-400 text-black active:text-black/80"

      "outline" ->
        "border border-neutral-800 hover:border-neutral-900 hover:bg-neutral-100 active:text-black/80"

      "outline-danger" ->
        "border border-red-500 hover:border-red-700 hover:bg-red-100 text-red-700 active:text-black/80"

      "link" ->
        "border-0 bg-transparent px-0"
    end
  end
end
