defmodule SavvyFlagsWeb.FeatureLive.Components do
  use SavvyFlagsWeb, :html

  alias SavvyFlags.Features
  alias SavvyFlags.Features.Feature

  import SavvyFlagsWeb.FeatureLive.Components.Rule
  import SavvyFlagsWeb.FeatureLive.Components.Revision

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
        </div>
      </div>
      <div class="text-right">
        <p class="font-bold">Revisions</p>
        <div class="flex gap-4">
          <%= if @feature.last_revision.status == :draft do %>
            <.button variant="primary" phx-click="publish-revision" size="sm">Publish</.button>
            <.button
              :if={@feature.last_revision.revision_number > 1}
              variant="outline"
              phx-click="discard-revision"
              size="sm"
            >
              Discard
            </.button>
          <% end %>
          <.dropdown id="revision-dropdown">
            <:dropdown_button>
              <.revision revision={@feature.last_revision} />
              <.icon name="hero-chevron-down-solid" class="ml-2 h-4 w-4" />
            </:dropdown_button>

            <.dropdown_item
              :for={revision <- @feature.revisions}
              :if={revision.id != @feature.last_revision.id}
            >
              <div
                class="flex gap-4"
                phx-click="rollback"
                phx-value-revision-number={revision.revision_number}
              >
                <.revision revision={revision} />
              </div>
            </.dropdown_item>
          </.dropdown>
        </div>
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
        <.rule
          :for={rule <- @environment.rules}
          feature={@feature}
          environment={@environment}
          rule={rule}
        />
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
