defmodule SavvyFlagsWeb.FeatureLive.FeatureRuleComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Attributes
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureRuleCondition

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative prevent-drag">
      <div class="absolute top-1 right-1">
        <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/#{@feature_rule}"}>
          <.icon name="hero-pencil-square" class="h-5 w-5 text-gray-500 hover:text-gray-700" />
        </.link>
        <.button
          type="button"
          variant="link"
          phx-click="delete-feature-rule"
          phx-target={@myself}
          data-confirm="Are you sure?"
        >
          <.icon name="hero-trash" class="h-5 w-5 text-red-500 hover:text-red-700" />
        </.button>
      </div>

      <p class="mb-3">
        <span class="text-neutral-500 text-sm">#{@feature_rule.position + 1}</span>
        <span class="font-semibold">{@feature_rule.description}</span>
      </p>
      <p class="mb-2 text-sm">
        <span class="font-semibold">Conditions</span>
        <span
          :if={length(@feature_rule.feature_rule_conditions) == 0}
          class="italic mb-3 text-gray-600"
        >
          No rules defined yet
        </span>
      </p>
      <div>
        <div
          :for={condition <- @feature_rule.feature_rule_conditions}
          class="mb-4 first:before:content-['IF'] not-first:before:content-['AND'] before:font-light before:italic before:mr-2 ml-3 first:ml-7 text-sm"
        >
          <.code_label value={condition.attribute.name} variant="black" />
          <span class="mx-3 font-semibold">
            {Keyword.get(SavvyFlags.Features.FeatureRuleCondition.mapping(), condition.type)}
          </span>
          <span :if={condition.type == :sample} class="inline-block mb-1">
            <.code_label value={condition.value} class="mr-1 mb-2" variant="green" border={false} />%
          </span>
          <span
            :for={v <- String.split(condition.value, ",")}
            :if={condition.type in [:in, :not_in]}
            class="inline-block mb-1"
          >
            <.code_label value={v} class="mr-1 mb-2" variant="green" border={false} />
          </span>
          <.code_label
            :if={condition.type not in [:in, :not_in, :sample]}
            value={condition.value}
            variant="green"
            border={false}
          />
        </div>
      </div>
      <p class="font-semibold mb-2 text-sm">
        Forced value <.code_label value={@feature_rule.value.value} variant="black" />
      </p>
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
  def handle_event("edit", _, socket) do
    {:noreply, assign(socket, edit: true)}
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

  def handle_event("edit-feature-rule", _, socket) do
    socket
    |> assign(:edit_mode, true)
    |> noreply()
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
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
