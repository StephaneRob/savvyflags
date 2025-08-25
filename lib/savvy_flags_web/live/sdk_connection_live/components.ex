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
    <div class="mt-5">
      <p class="font-bold w-1/4 mb-2">Mode</p>
      <p class="mb-4">{SavvyFlags.SdkConnections.SdkConnection.mode(@sdk_connection.mode)}</p>

      <p class="font-bold w-1/4 mb-2">Full API endpoint</p>
      <p class="mb-4">
        <code>
          <.copy_to_clipboard
            value={url(~p"/api/features/#{@sdk_connection.reference}")}
            id="endpoint"
          />
        </code>
      </p>

      <p class="font-bold w-1/4 mb-2">Client Key</p>
      <p class="mb-4">
        <code>
          <.copy_to_clipboard value={@sdk_connection.reference} id="key" />
        </code>
      </p>

      <p class="font-bold mb-3">Usage</p>
      <p class="mb-4">
        <code
          :if={@sdk_connection.mode == :remote_evaluated}
          class="font-mono bg-gray-800 text-white p-2"
        >
          curl -X POST {url(~p"/api/features/#{@sdk_connection.reference}")}
          <br /> -H 'content-type: application/json'
          <br />-d '&#123;"email": "example@gmail.com"&#125;'
        </code>
        <code
          :if={@sdk_connection.mode != :remote_evaluated}
          class="font-mono bg-gray-800 text-white p-2"
        >
          curl -X GET {url(~p"/api/features/#{@sdk_connection.reference}")}
        </code>
      </p>
    </div>
    """
  end

  def sandbox(assigns) do
    ~H"""
    <div class="mt-6 flex gap-5">
      <div :if={@sdk_connection.mode == :remote_evaluated} class="flex-1">
        <h1 class="text-md mb-3 font-semibold">
          Test your payload here
        </h1>
        <div :if={@sdk_connection.mode == :remote_evaluated} class="">
          <form phx-change="try-it-change">
            <textarea
              class="w-full rounded border  border-gray-200 font-mono"
              rows="5"
              id="textbox"
              name="attributes"
              phx-hook="TextareaCode"
            >{}</textarea>
            <p class="text-sm text-gray-700">
              <span :if={!@json_valid?} class="text-xs text-red-600"> Invalid json</span>
            </p>
          </form>
        </div>
      </div>
      <div :if={@sdk_connection.mode == :remote_evaluated} class="flex-1">
        <h1 class="text-md mb-3 font-semibold">
          API Response
        </h1>
        <div class="rounded shadow p-4 font-mono bg-gray-800 text-white">
          <pre><code class=""><%= @try_it_result %></code></pre>
        </div>
      </div>
    </div>

    <div :if={@sdk_connection.mode == :plain} class="mt-5">
      <h2 class="text-md mb-3 font-semibold">
        Plain rules
      </h2>
      <div class="rounded shadow p-4 font-mono bg-gray-800 text-white">
        <pre><code class=""><%= @plain_rules %></code></pre>
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
                "inline-block px-4 py-2 text-neutral-600 border-b-2 border-neutral-600 rounded-t-lg active hover:text-neutral-700 hover:border-neutral-700",
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
