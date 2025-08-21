defmodule SavvyFlagsWeb.FirstRunLive do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.Accounts
  alias SavvyFlags.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Welcome to SavvyFlags!
        <:subtitle>
          Create your first account to start flagging
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="first_run_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email *" required />
        <.input field={@form[:password]} type="password" label="Password *" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">GO! 🚀</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if [] == Accounts.list_users() do
      changeset = Accounts.change_user_registration(%User{})

      socket =
        socket
        |> assign(trigger_submit: false, check_errors: false)
        |> assign_form(changeset)

      {:ok, socket, temporary_assigns: [form: nil]}
    else
      socket
      |> redirect(to: ~p"/")
      |> put_flash(:error, "You must ask your admistrator to invite you.")
      |> ok()
    end
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "role", "owner")

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
