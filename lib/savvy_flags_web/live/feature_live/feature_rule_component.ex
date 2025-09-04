defmodule SavvyFlagsWeb.FeatureLive.RuleComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Attributes
  alias SavvyFlags.Features

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative prevent-drag">
      <div class="absolute top-1 right-1">
        <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/#{@rule}"}>
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
        <span class="font-semibold">{@rule.description}</span>
        <span class="text-neutral-500 text-xs">#{@rule.position + 1}</span>
      </p>
      <p class="mb-2 text-sm">
        <span class="font-semibold">Conditions</span>
        <span
          :if={length(@rule.conditions) == 0}
          class="italic mb-3 text-gray-600"
        >
          No rules defined yet
        </span>
      </p>
      <div>
        <div
          :for={condition <- @rule.conditions}
          class="mb-4 first:before:content-['IF'] not-first:before:content-['AND'] before:font-light before:italic before:mr-2 ml-3 first:ml-7 text-sm"
        >
          <.badge value={condition.attribute} />
          <span class="mx-3 font-semibold">
            {Keyword.get(SavvyFlags.Features.RuleCondition.mapping(), condition.type)}
          </span>
          <span :if={condition.type == :sample} class="inline-block mb-1">
            <.badge value={condition.value} class="mr-1 mb-2" />%
          </span>
          <span
            :for={v <- String.split(condition.value, ",")}
            :if={condition.type in [:in, :not_in]}
            class="inline-block mb-1"
          >
            <.badge value={v} class="mr-1 mb-2" />
          </span>
          <.badge
            :if={condition.type not in [:in, :not_in, :sample]}
            value={condition.value}
          />
        </div>
      </div>
      <p class="font-semibold mb-2 text-sm">
        Forced value <.badge value={@rule.value.value} />
      </p>
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
  def handle_event("edit", _, socket) do
    {:noreply, assign(socket, edit: true)}
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
    feature = socket.assigns.feature
    current_user = socket.assigns.current_user

    Features.Revisions.delete_rule_with_revision(
      rule,
      feature,
      current_user
    )

    send(self(), {__MODULE__, {:deleted, rule}})
    {:noreply, socket}
  end
end
