defmodule SavvyFlagsWeb.FeatureLive.Components do
  use SavvyFlagsWeb, :html
  alias SavvyFlags.Features
  alias SavvyFlags.Features.Feature

  attr :feature, Feature, required: true

  def feature_detail(assigns) do
    ~H"""
    <div class="flex justify-between">
      <div>
        <p class="mb-2">
          <span class="not-italic font-bold text-black">Description:</span>
          <span :if={@feature.description not in [nil, ""]} class="text-sm ">
            {@feature.description}
          </span>
          <span
            :if={@feature.description in [nil, ""]}
            class="text-sm italic text-gray-700 font-normal"
          >
            No description provided
          </span>
        </p>
        <div class="flex gap-6">
          <div>
            <p class="text-sm font-semibold mb-2">
              Type <.badge value={@feature.last_revision.value.type} />
            </p>
            <p></p>
          </div>
          <div>
            <p class="text-sm font-semibold mb-2">
              Default value <.badge value={@feature.last_revision.value.value} />
            </p>
          </div>
          <div>
            <p class="text-sm font-semibold mb-2">
              Last used at: <.stats feature={@feature} />
            </p>
          </div>
          <div>
            <p class="text-sm font-semibold mb-2">
              Revision: <.badge value={"v#{@feature.last_revision.revision_number}"} />
              <.badge
                :if={@feature.last_revision.status == :draft}
                value={"#{@feature.last_revision.status}"}
                variant="warning"
              />
              <.badge
                :if={@feature.last_revision.status == :published}
                value={"#{@feature.last_revision.status}"}
                variant="success"
              />
            </p>
          </div>
        </div>
      </div>
      <div>
        <%= if @feature.last_revision.status == :draft do %>
          <.button variant="primary" phx-click="publish-revision">Publish</.button>
          <.button
            :if={@feature.last_revision.revision_number > 1}
            variant="warning"
            phx-click="discard-revision"
          >
            Discard
          </.button>
        <% else %>
          <ul>
            <li :for={revision <- @feature.revisions}>
              <.badge value={"v#{revision.revision_number}"} variant="code" />
              <.badge
                :if={revision.status == :draft}
                value={"#{revision.status}"}
                variant="warning"
              />
              <.badge
                :if={revision.status == :unpublished}
                value={"#{revision.status}"}
              />
              <.badge
                :if={revision.status == :published}
                value={"#{revision.status}"}
                variant="success"
              />
              <.button
                :if={revision.status != :published}
                phx-click="rollback"
                phx-value-revision-number={revision.revision_number}
              >
                Rollback to
              </.button>
            </li>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  attr :feature, :map
  attr :environment, :map
  attr :current_user, :map

  def feature_environment_detail(assigns) do
    ~H"""
    <.list_rules feature={@feature} environment={@environment} current_user={@current_user} />
    """
  end

  attr :feature, :map
  attr :rules, :list
  attr :environment, :map
  attr :current_user, :map

  def list_rules(assigns) do
    ~H"""
    <div class="mt-6">
      <div :if={@environment.rules == []} class="text-center">
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
        <%= for rule <- @environment.rules do %>
          <.rule
            feature={@feature}
            rule={rule}
            environment={@environment}
            current_user={@current_user}
          />
        <% end %>
      </div>
    </div>
    <div :if={@environment.rules != []} class="mt-5">
      <.link patch={~p"/features/#{@feature}/environments/#{@environment}/rules/new"}>
        <.button>
          Add rule
        </.button>
      </.link>
    </div>
    """
  end

  attr :feature, :map
  attr :rule, :map
  attr :environment, :map
  attr :current_user, :map

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
          <.live_component
            module={SavvyFlagsWeb.FeatureLive.RuleComponent}
            id={@rule.reference || :new}
            rule={@rule}
            feature={@feature}
            current_user={@current_user}
            environment={@environment}
          />
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
      <:col :let={environment} label="Rules">{length(environment.rules)}</:col>
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

  attr :feature, Feature, required: true

  def stats(assigns) do
    stats = assigns.feature.stats

    assigns =
      assign_new(assigns, :last_stat, fn ->
        if Enum.any?(stats) do
          List.first(stats)
        end
      end)

    ~H"""
    <span :if={@last_stat} class="text-xs">
      {Timex.from_now(@last_stat.last_used_at, "en")} ({@last_stat.environment.name})
    </span>
    <span :if={!@last_stat} class="text-xs italic text-gray-500">Never used</span>

    <%= if Features.stale?(@feature) do %>
      <br />
      <.badge value="Stale" variant="warning" size="sm" />
    <% end %>
    """
  end
end
