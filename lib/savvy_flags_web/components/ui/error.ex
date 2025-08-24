defmodule SavvyFlagsWeb.UI.Error do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext
  import SavvyFlagsWeb.UI.Icon

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end
end
