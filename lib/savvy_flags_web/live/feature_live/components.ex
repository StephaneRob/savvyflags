defmodule SavvyFlagsWeb.FeatureLive.Components do
  use SavvyFlagsWeb, :html

  attr :feature, :map

  def feature_detail(assigns) do
    ~H"""
    <div>
      <p class="text-sm font-semibold mb-2">
        Type <.badge value={@feature.default_value.type} />
      </p>
      <p></p>
    </div>
    <div>
      <p class="text-sm font-semibold mb-2">
        Default value <.badge value={@feature.default_value.value} />
      </p>
    </div>
    """
  end

  attr :feature, :map
  attr :environment, :map

  def feature_environment_detail(assigns) do
    ~H"""
    <.list_feature_rules feature={@feature} environment={@environment} />
    """
  end

  attr :feature, :map
  attr :feature_rules, :list
  attr :environment, :map

  def list_feature_rules(assigns) do
    ~H"""
    <div class="mt-6">
      <div :if={@environment.feature_rules == []} class="text-center">
        <p class="font-semibold text-lg">Create your first rule</p>
        <div class="mt-5">
          <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/new"}>
            <.button>
              Add rule
            </.button>
          </.link>
        </div>
      </div>
      <div phx-hook="Sortable" id="frc-list">
        <%= for feature_rule <- @environment.feature_rules do %>
          <.feature_rule feature={@feature} feature_rule={feature_rule} environment={@environment} />
        <% end %>
      </div>
    </div>
    <div :if={@environment.feature_rules != []} class="mt-5">
      <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/new"}>
        <.button>
          Add rule
        </.button>
      </.link>
    </div>
    """
  end

  attr :feature, :map
  attr :feature_rule, :map
  attr :environment, :map

  def feature_rule(assigns) do
    scheduled_class = if(assigns[:feature_rule].scheduled, do: "opacity-50")
    assigns = Map.put(assigns, :scheduled_class, scheduled_class)

    ~H"""
    <div class="rounded shadow overflow-hidden mb-5" data-id={@feature_rule.id}>
      <div class="drag-ghost:opacity-0">
        <div class={[
          "feature-rule py-4 pl-9 pr-4  bg-white relative
    drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-gray-100 drag-ghost:border-0 drag-ghost:ring-0",
          @scheduled_class
        ]}>
          <span class="absolute top-3.5 left-2 z-50 cursor-grab text-gray-400 handler">
            <.icon name="hero-bars-3" class="w-5 h-5" />
          </span>
          <.live_component
            module={SavvyFlagsWeb.FeatureLive.FeatureRuleComponent}
            id={@feature_rule.reference || :new}
            feature_rule={@feature_rule}
            feature={@feature}
            environment={@environment}
          />
        </div>
        <div
          :if={@feature_rule.scheduled}
          class="opacity-100 bg-neutral-300 text-neutral-900 py-2 px-2 text-xs italic"
        >
          <p>
            <.icon name="hero-clock" class="h-4" /> This rule will be automatically activated on
            <span
              id={"fr-scheduled-#{@feature_rule.reference}"}
              phx-hook="LocalTime"
              title={@feature_rule.scheduled_at}
            >
              {@feature_rule.scheduled_at}
            </span>
            ({@feature_rule.scheduled_at} UTC)
          </p>
        </div>

        <div
          :if={!is_nil(@feature_rule.activated_at) && !@feature_rule.scheduled_at}
          class="opacity-100 bg-green-300 text-green-900 py-2 px-2 text-xs italic"
        >
          <p>
            <.icon name="hero-check" class="h-4" /> This rule has been automatically activated on
            <span
              id={"fr-activated-#{@feature_rule.reference}"}
              phx-hook="LocalTime"
              title={@feature_rule.activated_at}
            >
              {@feature_rule.activated_at}
            </span>
            ({@feature_rule.activated_at} UTC)
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :feature, :map
  attr :environments, :list

  def feature_environments(assigns) do
    ~H"""
    <.table
      id="feature-environments"
      rows={@environments}
      row_click={
        fn environment ->
          JS.patch(~p"/features/#{@feature}/environments/#{environment}")
        end
      }
    >
      <:col :let={environment} label="Name">
        <span class="flex items-center">
          <span
            class="mr-1 h-3 w-3 inline-block rounded-sm"
            style={"background-color: #{environment.color}"}
          >
          </span>
          <span class="capitalize">{environment.name}</span>
        </span>
      </:col>
      <:col :let={environment} label="Rules">{length(environment.feature_rules)}</:col>
      <:col :let={environment} label="Rules">{length(environment.feature_rules)}</:col>
      <:action :let={environment}>
        <form phx-change="toggle-feature-environment" phx-value-id={environment.id}>
          <.toggle
            label="Enabled?"
            checked={Enum.member?(@feature.environments_enabled, environment.id)}
            id={"feature_environments_#{environment.name}"}
            name={"feature_environments_#{environment.id}"}
          />
        </form>
      </:action>
    </.table>
    """
  end
end
