defmodule SavvyFlagsWeb.FeatureLive.Components.Rule do
  use SavvyFlagsWeb, :html

  alias SavvyFlags.Features.Rule
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Environments.Environment

  attr :feature, Feature, required: true
  attr :rule, Rule, required: true
  attr :environment, Environment, required: true

  def rule(assigns) do
    scheduled_class = if(assigns[:rule].scheduled, do: "opacity-50")
    assigns = Map.put(assigns, :scheduled_class, scheduled_class)

    ~H"""
    <div class="rounded shadow overflow-hidden mb-5" data-id={@rule.id}>
      <div class="drag-ghost:opacity-0">
        <div class={[
          "feature-rule py-4 pl-9 pr-4  bg-white relative
    drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-gray-100 drag-ghost:border-0 drag-ghost:ring-0",
          @scheduled_class
        ]}>
          <span class="absolute top-3.5 left-2 z-50 cursor-grab text-gray-400 handler">
            <.icon name="hero-bars-3" class="w-5 h-5" />
          </span>
          <div class="relative prevent-drag">
            <div class="absolute top-1 right-1">
              <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/#{@rule}"}>
                <.icon name="hero-pencil-square" class="h-5 w-5 text-gray-500 hover:text-gray-700" />
              </.link>
              <.button
                type="button"
                variant="link"
                phx-click="delete-rule"
                phx-value-reference={@rule.reference}
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
        </div>
        <div
          :if={@rule.scheduled}
          class="opacity-100 bg-neutral-300 text-neutral-900 py-2 px-2 text-xs italic"
        >
          <p>
            <.icon name="hero-clock" class="h-4" /> This rule will be automatically activated on
            <span
              id={"fr-scheduled-#{@rule.reference}"}
              phx-hook="LocalTime"
              title={@rule.scheduled_at}
            >
              {@rule.scheduled_at}
            </span>
            ({@rule.scheduled_at} UTC)
          </p>
        </div>

        <div
          :if={!is_nil(@rule.activated_at) && !@rule.scheduled_at}
          class="opacity-100 bg-green-300 text-green-900 py-2 px-2 text-xs italic"
        >
          <p>
            <.icon name="hero-check" class="h-4" /> This rule has been automatically activated on
            <span
              id={"fr-activated-#{@rule.reference}"}
              phx-hook="LocalTime"
              title={@rule.activated_at}
            >
              {@rule.activated_at}
            </span>
            ({@rule.activated_at} UTC)
          </p>
        </div>
      </div>
    </div>
    """
  end
end
