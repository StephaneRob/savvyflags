defmodule SavvyFlagsWeb.AttributeLive.Index do
  use SavvyFlagsWeb, :live_view

  alias SavvyFlags.Attributes
  alias SavvyFlags.Attributes.Attribute

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumb>
      <:items>Attributes</:items>
      <:actions>
        <.link patch={~p"/attributes/new"}>
          <.button>Add attribute</.button>
        </.link>
      </:actions>
      <:subtitle>
        Attributes can be used when targeting feature flags and must be passed to SDK.
      </:subtitle>
    </.breadcrumb>

    <.table id="attributes" rows={@streams.attributes}>
      <:col :let={{_, attribute}} label="Attribute"><code>{attribute.name}</code></:col>
      <:col :let={{_, attribute}} label="Data type"><.badge value={attribute.data_type} /></:col>
      <:col :let={{_, attribute}} label="Identifier"><.check value={attribute.identifier} /></:col>
      <:col :let={{_, attribute}} label="Description">{attribute.description}</:col>
      <:col :let={{_, attribute}} label="Remote?">
        <.check value={attribute.remote} />
      </:col>
      <:action :let={{_id, attribute}}>
        <.link patch={~p"/attributes/#{attribute}/edit"}>
          Edit
        </.link>
      </:action>
      <:action :let={{id, attribute}}>
        <.link
          :if={length(attribute.feature_rule_conditions) == 0}
          phx-click={JS.push("delete", value: %{id: attribute.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
        <span :if={length(attribute.feature_rule_conditions) > 0} class="text-gray-500 text-xs italic">
          Linked to {length(attribute.feature_rule_conditions)} rules
        </span>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="attribute-modal"
      show
      on_cancel={JS.patch(~p"/attributes")}
    >
      <.live_component
        module={SavvyFlagsWeb.AttributeLive.FormComponent}
        id={@attribute.id || :new}
        title={@page_title}
        action={@live_action}
        attribute={@attribute}
        patch={~p"/attributes"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    attributes = Attributes.list_attributes(:feature_rule_conditions)

    socket =
      socket
      |> stream_configure(:attributes, dom_id: & &1.reference)
      |> stream(:attributes, attributes)
      |> assign(:active_nav, :attributes)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"reference" => reference}) do
    socket
    |> assign(:page_title, "Edit attribute")
    |> assign(:attribute, Attributes.get_attribute_by_reference!(reference))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New attribute")
    |> assign(:attribute, %Attribute{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing attributes")
    |> assign(:attribute, nil)
  end

  @impl true
  def handle_info(
        {SavvyFlagsWeb.AttributeLive.FormComponent, {:saved, attribute}},
        socket
      ) do
    {:noreply, stream_insert(socket, :attributes, attribute)}
  end
end
