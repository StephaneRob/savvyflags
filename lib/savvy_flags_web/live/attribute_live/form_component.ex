defmodule SavvyFlagsWeb.AttributeLive.FormComponent do
  use SavvyFlagsWeb, :live_component
  alias SavvyFlags.Attributes
  alias SavvyFlags.Attributes.Attribute

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="attribute-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input
          field={@form[:data_type]}
          label="Data type"
          options={Attribute.data_types()}
          type="select"
        />
        <.input field={@form[:identifier]} label="Identifier" type="checkbox" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <div>
          <p class="font-bold ">Remote</p>
          <p class="mt-0">
            Remote config allows you to search attribute value from your own data by providing an external endpoint
          </p>
        </div>
        <.toggle
          label="Remote?"
          checked={@form[:remote].value}
          id="attribute_remote"
          name="attribute[remote]"
        />

        <%= if @form[:remote].value in [true, "on"] do %>
          <.input
            field={@form[:url]}
            label="URL *"
            type="text"
            placeholder="http://myapp.com/api/attribute"
          />
          <.input
            field={@form[:access_token]}
            label="Access token"
            type="text"
            hint="This token is encrypted in our database."
          />
          <.button
            type="button"
            variant="outline"
            phx-click="verify-remote"
            class="-mt-2"
            phx-target={@myself}
            phx-value-url={@form[:url].value}
            phx-value-access-token={@form[:access_token].value}
          >
            Verify remote
          </.button>
          <div :if={@remote_result}>
            <p class="italic text-sm mb-3">This is a sample of your API response</p>
            <pre class="text-xs p-3 border border-gray-100 rounded bg-gray-50"><code><%= @remote_result %></code></pre>
          </div>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save attribute</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{attribute: attribute} = assigns, socket) do
    changeset = Attributes.change_attribute(attribute)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:remote_result, nil)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"attribute" => attribute_params}, socket) do
    changeset =
      socket.assigns.attribute
      |> Attributes.change_attribute(attribute_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"attribute" => attribute_params}, socket) do
    remote = Map.get(attribute_params, "remote")

    attribute_params =
      attribute_params
      |> Map.put("remote", if(remote == "on", do: true, else: false))

    save_attribute(socket, socket.assigns.action, attribute_params)
  end

  def handle_event("verify-remote", %{"url" => url} = params, socket) do
    access_token = Map.get(params, "access-token")

    # Instead of result check valid contract [{name, value}]
    value =
      SavvyFlags.AttributeClient.request(url, access_token, "")
      |> Enum.take(2)
      |> Jason.encode!(pretty: true)

    socket
    |> assign(:remote_result, value)
    |> noreply()
  end

  defp save_attribute(socket, :edit, attribute_params) do
    case Attributes.update_attribute(socket.assigns.attribute, attribute_params) do
      {:ok, attribute} ->
        attribute = SavvyFlags.Repo.preload(attribute, :feature_rule_conditions)
        notify_parent({:saved, attribute})

        {:noreply,
         socket
         |> put_flash(:info, "Attribute updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attribute(socket, :new, attribute_params) do
    case Attributes.create_attribute(attribute_params) do
      {:ok, attribute} ->
        attribute = SavvyFlags.Repo.preload(attribute, :feature_rule_conditions)
        notify_parent({:saved, attribute})

        {:noreply,
         socket
         |> put_flash(:info, "Attribute created successfully")
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
