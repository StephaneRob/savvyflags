defmodule SavvyFlagsWeb.FeatureLive.RuleFormComponent do
  alias SavvyFlags.Features.RuleCondition
  use SavvyFlagsWeb, :live_component

  alias Ecto.Changeset
  alias SavvyFlags.Attributes
  alias SavvyFlags.Features

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle :if={@action == :fr_new}>
          Add a new rule to {@environment.name}
        </:subtitle>
        <:subtitle :if={@action == :fr_edit}>
          Edit {@environment.name} rule
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        phx-submit="save"
        phx-target={@myself}
        phx-change="validate"
        id="feature-rule-form"
      >
        <.input
          field={@form[:description]}
          label="Description *"
          id={"fr_description_#{@rule.reference}"}
          placeholder="ex: Activate for gmail.com user"
        />
        <.input type="hidden" field={@form[:position]} />
        <fieldset class="flex flex-col gap-2">
          <legend class="font-bold">Conditions</legend>
          <.inputs_for :let={form_conditions} field={@form[:conditions]}>
            <div class={"flex gap-2 items-center" <> if(form_conditions[:delete].value == "true", do: " opacity-20", else: "")}>
              <.input
                field={form_conditions[:attribute]}
                type="select"
                options={Enum.into(@attributes, [], &{&1.name, &1.name})}
                id={"frc_attribute_id_#{form_conditions[:reference].value}"}
              />

              <.input
                field={form_conditions[:type]}
                type="select"
                options={SavvyFlags.Features.RuleCondition.types()}
                id={"frc_type_id_#{form_conditions[:reference].value}"}
              />

              <.value_input
                attribute_id={form_conditions[:attribute_id].value}
                condition_type={form_conditions[:type].value}
                field={form_conditions[:value]}
              />

              <%!-- <.input
                field={form_conditions[:position]}
                value={form_conditions.index}
                type="hidden"
                id={"frc_position_id_#{form_conditions[:reference].value}"}
              /> --%>

              <.button
                class="mt-2"
                type="button"
                variant="link"
                size="sm"
                phx-value-index={form_conditions.index}
                phx-click="delete-line"
                phx-target={@myself}
              >
                <.icon name="hero-trash" class="h-3 w-3 text-red-500" />
              </.button>
              <.input
                field={form_conditions[:delete]}
                type="hidden"
                id={"frc_delete_#{form_conditions[:reference].value}"}
              />
            </div>
          </.inputs_for>
          <%= if @form[:conditions].value == [] do %>
            <p class="text-xs text-neutral-500">
              No conditions created yet.
              <.icon name="hero-exclamation-triangle-solid" class="h-3 w-3" />
              If no conditions provided the rule will always match and return de forced value.
            </p>
          <% end %>
          <div>
            <.button
              class="mt-2"
              type="button"
              phx-click="add-line"
              phx-target={@myself}
              size="sm"
              variant="ghost"
            >
              <.icon name="hero-plus" class="mr-1 h-4 w-4" /> Add condition
            </.button>
          </div>
        </fieldset>
        <.inputs_for :let={fr_value} field={@form[:value]}>
          <.input
            field={fr_value[:type]}
            value={@feature.last_revision.value.type}
            type="hidden"
            class="h-0"
            id={"frv_type_#{@rule.reference}"}
          />
          <%= if @feature.last_revision.value.type == :boolean do %>
            <div>
              <.label>Forced value</.label>
              <.input
                field={fr_value[:value]}
                label="Active?"
                type="checkbox"
                id={"frv_value_#{@rule.reference}"}
              />
            </div>
          <% else %>
            <.input
              field={fr_value[:value]}
              label="Forced value"
              id={"frv_value_#{@rule.reference}"}
            />
          <% end %>
        </.inputs_for>

        <.toggle
          label="Scheduled rule?"
          checked={@form[:scheduled].value}
          id="fr_scheduled"
          name="rule[scheduled]"
        />

        <%= if @form[:scheduled].value in [true, "on"] do %>
          <div phx-update="ignore" id="scheduled-datatime" class="-mt-4">
            <.input
              field={@form[:scheduled_at]}
              phx-hook="DateTimePicker"
              type="text"
              label="Schedule at"
            />
          </div>
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save rule</.button>
          <.button
            phx-click="cancel"
            phx-target={@myself}
            type="button"
            variant="outline"
          >
            Cancel
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{rule: rule} = assigns, socket) do
    %{feature: feature, environment: environment} = assigns

    changeset =
      Features.change_rule(rule, %{
        "feature_id" => feature.id,
        "environment_id" => environment.id
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:attributes, Attributes.list_attributes())
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"rule" => rule_params}, socket) do
    scheduled = Map.get(rule_params, "scheduled")

    rule_params =
      Map.put(rule_params, "scheduled", if(scheduled == "on", do: true, else: false))

    changeset =
      socket.assigns.rule
      |> Features.change_rule(rule_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("delete-feature-rule", _, socket) do
    rule = socket.assigns.rule
    Features.delete_rule(rule)
    send(self(), {__MODULE__, {:deleted, rule}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"rule" => rule_params}, socket) do
    rule = socket.assigns.rule
    action = if rule.id, do: :edit, else: :new
    scheduled = Map.get(rule_params, "scheduled")

    rule_params =
      Map.put(rule_params, "scheduled", if(scheduled == "on", do: true, else: false))

    save_rule(socket, action, rule_params)
  end

  def handle_event("add-line", _, socket) do
    attributes = socket.assigns.attributes

    socket =
      update(socket, :form, fn %{source: changeset} ->
        existing = Changeset.get_embed(changeset, :conditions)
        new_condition = %RuleCondition{attribute: List.first(attributes).name}
        changeset = Changeset.put_embed(changeset, :conditions, existing ++ [new_condition])
        to_form(changeset)
      end)

    {:noreply, socket}
  end

  def handle_event("delete-line", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      update(socket, :form, fn %{source: changeset} ->
        existing = Changeset.get_embed(changeset, :conditions)
        {_to_delete, rest} = List.pop_at(existing, index)

        changeset
        |> Changeset.put_embed(:conditions, rest)
        |> to_form()
      end)

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket
    |> push_patch(to: socket.assigns.patch)
    |> noreply()
  end

  defp save_rule(socket, :edit, rule_params) do
    feature = socket.assigns.feature
    user = socket.assigns.current_user
    rule = socket.assigns.rule

    case Features.Revisions.update_rule_with_revision(
           rule,
           feature,
           user,
           rule_params
         ) do
      {:ok, rule} ->
        send(self(), {__MODULE__, {:saved, rule}})

        socket
        |> put_flash(:info, "Feature rule updated successfully")
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign_form(changeset)
        |> noreply()
    end
  end

  defp save_rule(socket, :new, rule_params) do
    %{feature: feature, environment: environment, current_user: current_user} = socket.assigns

    rule_params =
      Map.merge(rule_params, %{
        "revision_id" => feature.last_revision.id,
        "environment_id" => environment.id
      })

    case Features.Revisions.create_rule_with_revision(
           feature,
           current_user,
           rule_params
         ) do
      {:ok, rule} ->
        send(self(), {__MODULE__, {:saved, rule}})

        socket
        |> put_flash(:info, "Feature rule created successfully")
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp value_input(assigns) do
    # assigns =
    #   Map.merge(assigns, %{
    #     attribute: Attributes.get_attribute!(attribute_id)
    #   })

    do_value_input(assigns)
  end

  # defp do_value_input(
  #        %{
  #          attribute: %Attribute{remote: true} = attribute,
  #          condition_type: condition_type
  #        } = assigns
  #      )
  #      when condition_type not in [:sample] do
  #   multiple = condition_type in [:in, "in", :not_in, "not_in"]

  #   onchange = fn value ->
  #     SavvyFlags.AttributeClient.request(
  #       attribute,
  #       value
  #     )
  #   end

  #   assigns = Map.merge(assigns, %{onchange: onchange, multiple: multiple})

  #   ~H"""
  #   <.live_component
  #     module={SavvyFlagsWeb.Search}
  #     id={"test-search-#{@field.name}"}
  #     field={@field}
  #     onchange={@onchange}
  #     multiple={@multiple}
  #   />
  #   """
  # end

  defp do_value_input(%{condition_type: condition_type} = assigns)
       when condition_type in [:sample, "sample"] do
    ~H"""
    <div class="flex items-center mt-1">
      <.input field={@field} type="range" min="0" max="100" />
      <div class="ml-3 mt-2">
        <.label>{@field.value}</.label>
      </div>
    </div>
    """
  end

  defp do_value_input(assigns) do
    ~H"""
    <.input field={@field} type="text" />
    """
  end
end
