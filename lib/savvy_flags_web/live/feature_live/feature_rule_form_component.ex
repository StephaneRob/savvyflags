defmodule SavvyFlagsWeb.FeatureLive.FeatureRuleFormComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Attributes
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureRuleCondition

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

      <.simple_form for={@form} phx-submit="save" phx-target={@myself} phx-change="validate">
        <.input
          field={@form[:description]}
          label="Description *"
          id={"fr_description_#{@feature_rule.reference}"}
          placeholder="ex: Activate for gmail.com user"
        />
        <.input type="hidden" field={@form[:position]} />
        <fieldset class="flex flex-col gap-2">
          <legend class="font-bold">Conditions</legend>
          <.inputs_for :let={f_feature_rule_condition} field={@form[:feature_rule_conditions]}>
            <div class={"flex gap-3 items-start" <> if(f_feature_rule_condition[:delete].value == "true", do: " opacity-20", else: "")}>
              <.input
                field={f_feature_rule_condition[:attribute_id]}
                type="select"
                options={Enum.into(@attributes, [], &{&1.name, &1.id})}
                id={"frc_attribute_id_#{f_feature_rule_condition[:reference].value}"}
              />

              <.input
                field={f_feature_rule_condition[:type]}
                type="select"
                options={SavvyFlags.Features.FeatureRuleCondition.types()}
                id={"frc_type_id_#{f_feature_rule_condition[:reference].value}"}
              />

              <.value_input
                attribute_id={f_feature_rule_condition[:attribute_id].value}
                condition_type={f_feature_rule_condition[:type].value}
                field={f_feature_rule_condition[:value]}
              />

              <.input
                field={f_feature_rule_condition[:position]}
                value={f_feature_rule_condition.index}
                type="hidden"
                id={"frc_position_id_#{f_feature_rule_condition[:reference].value}"}
              />
              <.input
                field={f_feature_rule_condition[:delete]}
                type="hidden"
                id={"frc_delete_#{f_feature_rule_condition[:reference].value}"}
              />
              <.button
                class="mt-2"
                type="button"
                variant="outline-danger"
                phx-value-index={f_feature_rule_condition.index}
                phx-click="delete-line"
                phx-target={@myself}
              >
                delete
              </.button>
            </div>
            <hr />
          </.inputs_for>
          <%= if @form[:feature_rule_conditions].value == [] do %>
            <p class="italic text-sm text-neutral-700">
              No conditions yet. <br />
              <span class="text-orange-700">
                <.icon name="hero-exclamation-triangle" class="mr-1 h-3 w-3" />
                If no conditions provided the rule will always match and return de forced value.
              </span>
            </p>
          <% end %>
          <div>
            <.button class="mt-2" type="button" phx-click="add-line" phx-target={@myself} size="sm">
              Add condition
            </.button>
          </div>
        </fieldset>
        <.inputs_for :let={fr_value} field={@form[:value]}>
          <.input
            field={fr_value[:type]}
            value={@feature.default_value.type}
            type="hidden"
            class="h-0"
            id={"frv_type_#{@feature_rule.reference}"}
          />
          <%= if @feature.default_value.type == :boolean do %>
            <.label>Forced value</.label>
            <.input
              field={fr_value[:value]}
              label="Active?"
              type="checkbox"
              id={"frv_value_#{@feature_rule.reference}"}
            />
          <% else %>
            <.input
              field={fr_value[:value]}
              label="Forced value"
              id={"frv_value_#{@feature_rule.reference}"}
            />
          <% end %>
        </.inputs_for>

        <.toggle
          label="Scheduled rule?"
          checked={@form[:scheduled].value}
          id="fr_scheduled"
          name="feature_rule[scheduled]"
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
            phx-click="cancel-edit-feature-rule"
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
  def update(%{feature_rule: feature_rule} = assigns, socket) do
    %{feature: feature, environment: environment} = assigns

    changeset =
      Features.change_feature_rule(feature_rule, %{
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
  def handle_event("validate", %{"feature_rule" => feature_rule_params}, socket) do
    scheduled = Map.get(feature_rule_params, "scheduled")

    feature_rule_params =
      Map.put(feature_rule_params, "scheduled", if(scheduled == "on", do: true, else: false))

    changeset =
      socket.assigns.feature_rule
      |> Features.change_feature_rule(feature_rule_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("delete-feature-rule", _, socket) do
    feature_rule = socket.assigns.feature_rule
    Features.delete_feature_rule(feature_rule)
    send(self(), {__MODULE__, {:deleted, feature_rule}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"feature_rule" => feature_rule_params}, socket) do
    feature_rule = socket.assigns.feature_rule
    action = if feature_rule.id, do: :edit, else: :new
    scheduled = Map.get(feature_rule_params, "scheduled")

    feature_rule_params =
      Map.put(feature_rule_params, "scheduled", if(scheduled == "on", do: true, else: false))

    save_feature_rule(socket, action, feature_rule_params)
  end

  def handle_event("add-line", _, socket) do
    attributes = socket.assigns.attributes

    socket =
      update(socket, :form, fn %{source: changeset} ->
        existing = Ecto.Changeset.get_assoc(changeset, :feature_rule_conditions)

        changeset =
          Ecto.Changeset.put_assoc(
            changeset,
            :feature_rule_conditions,
            existing ++
              [
                %FeatureRuleCondition{
                  attribute_id: List.first(attributes).id,
                  reference: SavvyFlags.PrefixedId.generate(:feature_rule_condition)
                }
              ]
          )

        to_form(changeset)
      end)

    {:noreply, socket}
  end

  def handle_event("delete-line", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      update(socket, :form, fn %{source: changeset} ->
        existing = Ecto.Changeset.get_assoc(changeset, :feature_rule_conditions)
        {to_delete, rest} = List.pop_at(existing, index)

        new_frc =
          if Ecto.Changeset.change(to_delete).data.id do
            List.replace_at(existing, index, Ecto.Changeset.change(to_delete, delete: "true"))
          else
            rest
          end

        changeset
        |> Ecto.Changeset.put_assoc(:feature_rule_conditions, new_frc)
        |> to_form()
      end)

    {:noreply, socket}
  end

  def handle_event("cancel-edit-feature-rule", _, socket) do
    %{feature_rule: feature_rule, environment: environment, feature: feature} = socket.assigns

    socket =
      if feature_rule.id do
        changeset =
          Features.change_feature_rule(feature_rule, %{
            "feature_id" => feature.id,
            "environment_id" => environment.id
          })

        socket
        |> assign(:edit_mode, false)
        |> assign_form(changeset)
      else
        send(self(), {__MODULE__, {:deleted, feature_rule}})
        socket
      end

    socket
    |> noreply()
  end

  defp save_feature_rule(socket, :edit, feature_rule_params) do
    feature_rule = socket.assigns.feature_rule

    case Features.update_feature_rule(feature_rule, feature_rule_params) do
      {:ok, feature_rule} ->
        send(self(), {__MODULE__, {:saved, feature_rule}})

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

  defp save_feature_rule(socket, :new, feature_rule_params) do
    %{feature: feature, environment: environment} = socket.assigns

    feature_rule_params =
      Map.merge(feature_rule_params, %{
        "feature_id" => feature.id,
        "environment_id" => environment.id
      })

    case Features.create_feature_rule(feature_rule_params) do
      {:ok, feature_rule} ->
        send(self(), {__MODULE__, {:saved, feature_rule}})

        socket
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def value_input(%{condition_type: condition_type} = assigns)
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

  def value_input(%{attribute_id: attribute_id, condition_type: condition_type} = assigns)
      when condition_type in [:in, "in", :not_in, "not_in"] do
    attribute = Attributes.get_attribute!(attribute_id)
    multiple = assigns.condition_type in [:in, "in", :not_in, "not_in"]

    onchange = fn value ->
      if attribute.remote do
        SavvyFlags.AttributeClient.request(
          attribute,
          value
        )
      end
    end

    assigns = Map.merge(assigns, %{onchange: onchange, multiple: multiple})

    ~H"""
    <.live_component
      module={SavvyFlagsWeb.Search}
      id={"test-search-#{@field.name}"}
      field={@field}
      onchange={@onchange}
      multiple={@multiple}
    />
    """
  end

  def value_input(assigns) do
    ~H"""
    <.input field={@field} type="text" />
    """
  end
end
