defmodule SavvyFlagsWeb.UI.Tag do
  use Phoenix.Component

  attr :variant, :string, default: "info"
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :close

  def tag(assigns) do
    ~H"""
    <code class={[tag_variant(@variant), @class, "rounded-xl py-1 px-2 text-xs font-normal"]}>
      {render_slot(@inner_block)}
      {render_slot(@close)}
    </code>
    """
  end

  defp tag_variant(variant) do
    case variant do
      "warning" -> " bg-amber-200 text-amber-800"
      "success" -> " bg-green-200 text-green-800"
      "danger" -> " bg-red-200 text-red-800"
      "neutral" -> " bg-neutral-200 text-neutral-800"
      _ -> " bg-neutral-200 text-neutral-800"
    end
  end
end
