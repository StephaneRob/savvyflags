defmodule SavvyFlagsWeb.UI.CopyToClipboard do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext
  alias Phoenix.LiveView.JS
  import SavvyFlagsWeb.UI.Icon

  attr :value, :string, required: true
  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :icon, :boolean, default: false

  def copy_to_clipboard(assigns) do
    ~H"""
    <button
      id={"copy-button-#{@id}"}
      class={@class}
      phx-click={
        JS.transition("hero-clipboard-document-check text-green-500 h-4 w-4",
          to: "#copy-button-#{@id}",
          time: 3000
        )
        |> JS.transition("hero-clipboard", to: "#copy-button-#{@id}")
        |> JS.dispatch("phx:copy", to: "#copy-#{@id}")
      }
    >
      <.icon id={"copy-icon-#{@id}"} name="hero-clipboard" class="h-4 w-4" />
    </button>
    <span id={"copy-#{@id}"} class={[@icon && "hidden"]}>
      {@value}
    </span>
    """
  end
end
