defmodule SavvyFlagsWeb.UI.Table do
  use Phoenix.Component
  use Gettext, backend: SavvyFlagsWeb.Gettext

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :class, :string, default: nil

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class={["w-[40rem] mt-11 sm:w-full rounded overflow-hidden", @class]}>
        <thead class="text-sm text-left leading-6 text-zinc-500 border-b border-zinc-200">
          <tr class="">
            <th :for={col <- @col} class="px-5 py-3 font-semibold text-black">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100  text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-neutral-100">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative px-5 py-2", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-2 pr-5">
                <span class="absolute right-0  sm:rounded-l-xl" />
                <span class={[
                  "relative",
                  i == 0 &&
                    "font-semibold text-zinc-900  "
                ]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 px-2 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0  sm:rounded-r-xl" />
                <div
                  :for={action <- @action}
                  class="relative inline-block ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
