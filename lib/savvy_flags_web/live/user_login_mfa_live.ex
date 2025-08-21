defmodule SavvyFlagsWeb.UserLoginMfaLive do
  use SavvyFlagsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Verify your account
      </.header>

      <.simple_form for={@form} id="mfa_form" action={~p"/users/log_in/mfa"} phx-update="ignore">
        <.input field={@form[:code]} type="text" label="Code *" required />

        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Verify
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    code = Phoenix.Flash.get(socket.assigns.flash, :code)
    form = to_form(%{"code" => code}, as: "mfa")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
