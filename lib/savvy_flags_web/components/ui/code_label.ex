defmodule SavvyFlagsWeb.UI.CodeLabel do
  use Phoenix.Component

  attr :value, :string, required: true
  attr :variant, :string, default: nil
  attr :border, :boolean, default: true
  attr :class, :string, default: nil

  def code_label(assigns) do
    css =
      case assigns[:variant] do
        "black" ->
          "bg-white text-black-800" <>
            if(assigns[:border], do: " border border-black-300", else: "")

        "green" ->
          "bg-teal-100 text-teal-800" <>
            if(assigns[:border], do: " border border-teal-300", else: "")

        _ ->
          "bg-neutral-100 text-neutral-800" <>
            if(assigns[:border], do: " border border-neutral-300", else: "")
      end

    assigns = Map.put(assigns, :css, css)

    ~H"""
    <code class={Tails.classes([@css, " rounded py-1/2 px-1 text-[10px] font-normal", @class])}>
      {@value}
    </code>
    """
  end
end
