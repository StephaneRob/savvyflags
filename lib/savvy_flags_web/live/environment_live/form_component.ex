defmodule SavvyFlagsWeb.EnvironmentLive.FormComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Environments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="environment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:color]} label="color" />
        <span
          class="h-4 w-4 inline-block rounded-sm"
          style={"background-color: #{@form[:color].value}"}
        >
        </span>
        <:actions>
          <.button phx-disable-with="Saving...">Save environment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{environment: environment} = assigns, socket) do
    changeset = Environments.change_environment(environment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"environment" => environment_params}, socket) do
    changeset =
      socket.assigns.environment
      |> Environments.change_environment(environment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"environment" => environment_params}, socket) do
    save_environment(socket, socket.assigns.action, environment_params)
  end

  defp save_environment(socket, :edit, environment_params) do
    case Environments.update_environment(socket.assigns.environment, environment_params) do
      {:ok, environment} ->
        notify_parent({:saved, environment})

        {:noreply,
         socket
         |> put_flash(:info, "Environment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_environment(socket, :new, environment_params) do
    case Environments.create_environment(environment_params) do
      {:ok, environment} ->
        notify_parent({:saved, environment})

        {:noreply,
         socket
         |> put_flash(:info, "Environment created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
