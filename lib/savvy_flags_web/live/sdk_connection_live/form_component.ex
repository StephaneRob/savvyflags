defmodule SavvyFlagsWeb.SdkConnection.FormComponent do
  alias SavvyFlags.SdkConnections
  use SavvyFlagsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="sdk-connection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <%= if @live_action == :new do %>
          <.live_component
            module={SavvyFlagsWeb.SelectMultiple}
            id="sdk-connection-projects"
            label="Projects"
            prompt="Add project..."
            field={@form[:project_ids]}
            options={Enum.into(@projects, [], &{&1.name, &1.id})}
          />

          <.input
            field={@form[:environment_id]}
            type="select"
            label="Environments"
            options={Enum.into(@environments, [], &{&1.name, &1.id})}
          />
        <% end %>

        <.input
          field={@form[:mode]}
          type="select"
          label="Mode"
          options={[Plain: "plain", "Remote Evaluated": "remote_evaluated"]}
          hint="Plain: High cacheable, but may leak sensitive info; Remote Evaluated: Completely hides business logic"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save SDK connection</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{sdk_connection: sdk_connection} = assigns, socket) do
    changeset =
      SdkConnections.change_sdk_connection(sdk_connection)
      |> Ecto.Changeset.put_change(:project_ids, Enum.map(sdk_connection.projects, & &1.id))

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"sdk_connection" => sdk_connection_params}, socket) do
    changeset =
      socket.assigns.sdk_connection
      |> SdkConnections.change_sdk_connection(sdk_connection_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"sdk_connection" => sdk_connection_params}, socket) do
    save_sdk_connection(socket, socket.assigns.action, sdk_connection_params)
  end

  defp save_sdk_connection(socket, :edit, sdk_connection_params) do
    case SdkConnections.update_sdk_connection(
           socket.assigns.sdk_connection,
           sdk_connection_params
         ) do
      {:ok, sdk_connection} ->
        notify_parent({:saved, sdk_connection})

        {:noreply,
         socket
         |> put_flash(:info, "SDK connection updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_sdk_connection(socket, :new, sdk_connection_params) do
    case SdkConnections.create_sdk_connection(sdk_connection_params) do
      {:ok, sdk_connection} ->
        notify_parent({:saved, sdk_connection})

        {:noreply,
         socket
         |> put_flash(:info, "SDK connection created successfully")
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
