defmodule SavvyFlagsWeb.FeatureLive.FormComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Features

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Start creating a new feature!</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="feature-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:key]}
          label="Key *"
          disabled={@action == :edit}
          hint={
            @configuration.feature_key_format &&
              "Must follow the format: #{@configuration.feature_key_format}"
          }
        />
        <.input field={@form[:description]} label="Description" />
        <.input field={@form[:project_id]} label="Project *" options={@form_projects} type="select" />
        <.inputs_for :let={f_default_value} field={@form[:default_value]}>
          <.input
            field={f_default_value[:type]}
            label="Value type"
            options={SavvyFlags.Features.Feature.value_types()}
            type="select"
          />
          <%= if f_default_value[:type].value == :boolean do %>
            <div>
              <.label>Default value</.label>
              <.input field={f_default_value[:value]} label="Active?" type="checkbox" />
            </div>
          <% else %>
            <.input field={f_default_value[:value]} label="Default value" />
          <% end %>
        </.inputs_for>

        <:actions>
          <.button phx-disable-with="Saving...">Save feature</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{feature: feature, projects: projects} = assigns, socket) do
    configuration = SavvyFlags.Configurations.get_configuration()
    form_projects = Enum.map(projects, &[key: &1.name, value: &1.id])
    changeset = Features.change_feature(feature)

    socket =
      socket
      |> assign_form(changeset)
      |> assign(:form_projects, form_projects)

    socket
    |> assign(assigns)
    |> assign(:configuration, configuration)
    |> assign_form(changeset)
    |> ok()
  end

  @impl true
  def handle_event("validate", %{"feature" => feature_params}, socket) do
    changeset =
      if socket.assigns.action == :edit do
        socket.assigns.feature
        |> Features.change_feature(feature_params)
        |> Map.put(:action, :validate)
      else
        socket.assigns.feature
        |> Features.Feature.create_changeset(feature_params)
        |> Map.put(:action, :validate)
      end

    socket =
      socket
      |> assign_form(changeset)

    assign_form(socket, changeset)
    |> noreply()
  end

  def handle_event("save", %{"feature" => feature_params}, socket) do
    save_feature(socket, socket.assigns.action, feature_params)
  end

  defp save_feature(socket, :edit, feature_params) do
    case Features.update_feature(socket.assigns.feature, feature_params) do
      {:ok, feature} ->
        notify_parent({:saved, feature})

        socket
        |> put_flash(:info, "Feature updated successfully")
        |> push_patch(to: ~p"/features")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        assign_form(socket, changeset)
        |> noreply()
    end
  end

  defp save_feature(socket, :new, feature_params) do
    case Features.create_feature(feature_params) do
      {:ok, feature} ->
        notify_parent({:saved, feature})

        socket
        |> put_flash(:info, "Feature created successfully")
        |> push_navigate(to: ~p"/features/#{feature}")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        assign_form(socket, changeset)
        |> noreply()
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
