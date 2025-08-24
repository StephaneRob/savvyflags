defmodule SavvyFlagsWeb.UI.CopyToClipboard do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext
  alias Phoenix.LiveView.JS
  import SavvyFlagsWeb.UI.Icon

  attr :value, :string, required: true
  attr :id, :string, required: true
  attr :class, :string, default: nil

  def copy_to_clipboard(assigns) do
    ~H"""
    <button
      id={"copy-button-#{@id}"}
      phx-click={
        JS.transition("hero-clipboard-document-check text-green-500",
          to: "#copy-button-#{@id}",
          time: 3000
        )
        |> JS.transition("hero-clipboard", to: "#copy-button-#{@id}")
        |> JS.dispatch("phx:copy", to: "#copy-#{@id}")
      }
    >
      <.icon id={"copy-icon-#{@id}"} name="hero-clipboard" />
    </button>
    <span id={"copy-#{@id}"} class={[@class]}>
      {@value}
    </span>
    """
  end
end
