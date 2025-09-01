defmodule SavvyFlagsWeb.ConfigurationLive do
  use SavvyFlagsWeb, :live_view
  alias SavvyFlags.Configurations

  on_mount {SavvyFlagsWeb.UserAuth, :require_admin}

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Configurations</:items>

      <:subtitle>
        Let's custom global settings for your instance
      </:subtitle>
    </.breadcrumb>

    <div class="max-w-96">
      <.simple_form for={@form} id="configuration-form" phx-change="validate" phx-submit="save">
        <div>
          <h2 class="text-xl font-semibold mb-2">General</h2>
          <.input field={@form[:feature_key_format]} label="Feature key format" />
          <p class=" text-xs text-gray-500">
            Specify the format for feature keys, using placeholders for dynamic values. ex:
            <code>&lt;app&gt;:&lt;feature&gt;-YYYY-MM-DD</code>
          </p>
        </div>
        <div>
          <.input field={@form[:stale_threshold]} label="Stale threshold (in days)" type="number" />
          <p class=" text-xs text-gray-500">
            Specify the number of days after which a feature is considered stale. ex: <code>30</code>. If not set, the default is 30 days (about 1 month).
          </p>
        </div>
        <div>
          <h2 class="text-xl font-semibold mb-2">Security</h2>
          <.toggle
            label="Enforce MFA for your users"
            checked={@form[:mfa_required].value}
            id={@form[:mfa_required].id}
            name={@form[:mfa_required].name}
          />
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save settings</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_, _session, socket) do
    configuration = Configurations.get_configuration()
    changeset = Configurations.change_configuration(configuration)

    socket
    |> assign(:active_nav, :configuration)
    |> assign(:configuration, configuration)
    |> assign_form(changeset)
    |> ok()
  end

  @impl true
  def handle_event("validate", %{"configuration" => config_attrs}, socket) do
    changeset =
      socket.assigns.configuration
      |> Configurations.change_configuration(config_attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"configuration" => config_attrs}, socket) do
    mfa_required = Map.get(config_attrs, "mfa_required")

    config_attrs =
      Map.put(config_attrs, "mfa_required", if(mfa_required == "on", do: true, else: false))

    save_coniguration(socket, config_attrs)
  end

  @impl true
  def handle_event("save", %{}, socket) do
    handle_event("save", %{"configuration" => %{"mfa_required" => "off"}}, socket)
  end

  @impl true
  def handle_event("validate", %{}, socket) do
    noreply(socket)
  end

  defp save_coniguration(socket, config_attrs) do
    case Configurations.update_configuration(socket.assigns.configuration, config_attrs) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Configuration updated successfully")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
