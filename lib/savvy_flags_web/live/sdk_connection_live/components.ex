defmodule SavvyFlagsWeb.SdkConnectionLive.Components do
  use SavvyFlagsWeb, :html
  alias Contex.Sparkline

  def metrics(assigns) do
    ~H"""
    <div class="mt-5">
      <div>
        <div class="bg-white border border-gray-200 rounded p-3">
          <div class="mb-5">
            <h1 class="text-lg font-bold">30 days API usage</h1>
            {make_plot(@data)}
          </div>
          <div class="flex gap-5">
            <div class="text-center">
              <h1 class="text-lg">Last 24 hours (requests)</h1>
              <p class="text-3xl font-bold">{@last_24_hours}</p>
            </div>
            <div class="text-center">
              <h1 class="text-lg">Last 30 days (requests)</h1>
              <p class="text-3xl font-bold">{@last_30_days}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def make_plot(data) do
    data
    |> Enum.map(fn
      # FIXME: use a real chart with x / y axis
      [_date_str, nil] ->
        # {date_str, 0}
        # Enum.random(0..10)
        0

      [_date_str, count] ->
        # {date_str, count}
        count
        # {date_str, count}
    end)
    |> Sparkline.new()
    |> Map.put(:height, 80)
    |> Map.put(:width, 700)
    |> Sparkline.colours("#EEE", "#000")
    |> Sparkline.draw()
  end

  def config(assigns) do
    ~H"""
    <div class="mt-5 flex gap-6">
      <div>
        <div class="flex gap-8">
          <div>
            <p class="font-bold mb-2">Mode</p>
            <p class="mb-4">{SavvyFlags.SdkConnections.SdkConnection.mode(@sdk_connection.mode)}</p>
          </div>
          <div>
            <p class="font-bold mb-2">Environment</p>
            <p class="mb-4">{@sdk_connection.environment.name}</p>
          </div>
          <div>
            <p class="font-bold mb-2">Projects</p>
            <p class="mb-4">{Enum.map_join(@sdk_connection.projects, ", ", & &1.name)}</p>
          </div>
        </div>
        <div class="flex gap-4">
          <div>
            <p class="font-bold mb-2">Full API endpoint</p>
            <p class="mb-4 text-sm font-mono">
              <.copy_to_clipboard
                value={url(~p"/api/features/#{@sdk_connection.reference}")}
                id="endpoint"
              />
            </p>
          </div>
          <div>
            <p class="font-bold mb-2">Client Key</p>
            <p class="mb-4 text-sm font-mono">
              <.copy_to_clipboard value={@sdk_connection.reference} id="key" />
            </p>
          </div>
        </div>

        <p class="font-bold mb-3">Usage</p>
        <div class="rounded shadow p-4 font-mono bg-neutral-800 text-xs text-white">
          <pre :if={@sdk_connection.mode == :remote_evaluated}><code class="">curl -X POST {url(~p"/api/features/#{@sdk_connection.reference}")} \<br />-H 'content-type: application/json' \<br />-d '&#123;"email": "example@gmail.com"&#125;'</code></pre>
          <pre :if={@sdk_connection.mode == :plain}><code>curl -X GET {url(~p"/api/features/#{@sdk_connection.reference}")}</code></pre>
        </div>
      </div>
      <div class="flex-1">
        <p class="font-bold mb-2">API response</p>
        <div class="rounded shadow p-4 font-mono bg-neutral-800 text-xs text-white">
          <pre><code class=""><%= @plain_rules %></code></pre>
        </div>
        <p :if={@sdk_connection.mode == :remote_evaluated} class="mt-2 text-xs text-neutral-700">
          The payload you send can contain any attributes you want. You can use these
          attributes in your rules to target specific users. For example, you could send the
          user's email, country, or any other attribute you want.
          <.link
            patch={~p"/sdk-connections/#{@sdk_connection}/sandbox"}
            class="font-semibold border-b border-neutral-400 hover:border-emerald-500 hover:text-emerald-500"
          >
            Try it here!
          </.link>
        </p>
      </div>
    </div>
    """
  end

  def sandbox(assigns) do
    attributes = assigns[:attributes] || []

    attributes_name =
      attributes
      |> Enum.sort_by(& &1.inserted_at)
      |> Enum.map(& &1.name)
      |> Jason.encode!()

    assigns = assign(assigns, attributes_name: attributes_name)

    ~H"""
    <div class="mt-6 flex gap-5">
      <div class="flex-1">
        <h1 class="text-md mb-3 font-semibold">
          Test your payload here
        </h1>
        <div class="">
          <div class="rounded border border-neutral-400">
            <div
              id="sandbox-remote"
              phx-hook="CodeEditor"
              phx-update="ignore"
              data-initial-value={@json}
              data-attributes={@attributes_name}
            />
          </div>

          <p class="text-xs text-neutral-700 mt-1">
            Available attributes:
            <.badge :for={attr <- @attributes} value={attr.name} size="sm" class="mr-1" />
          </p>
          <p :if={!@json_valid?} class="text-xs  text-red-600">Invalid JSON</p>

          <p class="mt-2 font-semibold">Curl</p>
          <div class="rounded shadow p-4 font-mono bg-neutral-800 text-xs text-white">
            <pre><code class="">curl -X POST {url(~p"/api/features/#{@sdk_connection.reference}")} \<br />-H 'content-type: application/json' \<br />-d '<%= Jason.encode!(Jason.decode!(@json)) %>'</code></pre>
          </div>
        </div>
      </div>
      <div class="flex-1">
        <h1 class="text-md mb-3 font-semibold">
          Evaluated API Response
        </h1>
        <div class="rounded shadow p-4 font-mono bg-neutral-800 text-xs text-white">
          <pre><code class=""><%= @evaluation_result %></code></pre>
        </div>
      </div>
    </div>
    """
  end

  slot :tabs, doc: "a tab for nav tabs"

  def navtabs(assigns) do
    ~H"""
    <div class="text-sm font-medium text-center text-gray-500 border-b border-gray-200">
      <ul class="flex flex-wrap -mb-px">
        <div :for={tab <- @tabs} class="mt-2 flex items-center gap-6">
          {render_slot(tab)}
        </div>
      </ul>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :name, :string, required: true
  attr :patch, :string, default: nil

  def tablink(assigns) do
    ~H"""
    <li class="me-2">
      <.link
        patch={@patch}
        class={
          Tails.classes([
            "inline-block px-4 py-2 border-b-2 border-transparent rounded-t-lg hover:text-gray-600 hover:border-gray-300",
            if(@active,
              do:
                "inline-block px-4 py-2 text-emerald-600 border-b-2 border-emerald-600 rounded-t-lg active hover:text-emerald-600 hover:border-emerald-600",
              else: ""
            )
          ])
        }
      >
        {@name}
      </.link>
    </li>
    """
  end
end
