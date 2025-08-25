defmodule SavvyFlagsWeb.UI.Badge do
  use Phoenix.Component

  attr :value, :string, required: true
  attr :variant, :string, values: ~w(code default), default: "default"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :class, :string, default: nil

  def badge(assigns) do
    ~H"""
    <span class={
      Tails.classes([
        "inline-flex items-center justify-center rounded px-2 py-1 text-xs font-semibold",
        variant(@variant),
        size(@size),
        @class
      ])
    }>
      {@value}
    </span>
    """
  end

  defp variant(variant) do
    case variant do
      "code" -> "border border-black-300 py-1/2 px-1 font-normal"
      _ -> "bg-neutral-200 text-neutral-900"
    end
  end

  defp size(size) do
    case size do
      "sm" -> "text-[10px]"
      "md" -> "text-xs"
      "lg" -> "text-sm"
    end
  end
end
