defmodule SavvyFlagsWeb.UserLive.FormComponent do
  use SavvyFlagsWeb, :live_component

  alias SavvyFlags.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle :if={@live_action == :new}>Invite a new user</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} label="Email" disabled={@live_action == :edit} />
        <.input field={@form[:role]} label="Role" type="select" options={SavvyFlags.Accounts.roles()} />
        <%= if @form[:role].value in [:member, "member"] do %>
          <fieldset class="flex flex-col gap-2">
            <legend class="font-bold mb-3">Access control</legend>
            <p class="mb-3">Customize member access per projects and / or features</p>

            <.toggle
              label="Full access?"
              checked={@form[:full_access].value}
              id="user_full_access"
              name="user[full_access]"
            />
            <%= if @form[:full_access].value not in ["on", true] do %>
              <.live_component
                module={SavvyFlagsWeb.SelectMultiple}
                id="user-projects"
                label="Projects"
                prompt="Add project..."
                field={@form[:project_ids]}
                options={Enum.into(@projects, [], &{&1.name, &1.id})}
              />

              <.live_component
                module={SavvyFlagsWeb.SelectMultiple}
                id="user-features"
                label="Features"
                prompt="Add feature..."
                field={@form[:feature_ids]}
                options={Enum.into(@features, [], &{&1.key, &1.id})}
              />

              <.live_component
                module={SavvyFlagsWeb.SelectMultiple}
                id="user-environnments"
                label="Environments"
                prompt="Add environment..."
                field={@form[:environment_ids]}
                options={Enum.into(@environments, [], &{&1.name, &1.id})}
              />
            <% end %>
          </fieldset>
        <% end %>
        <:actions>
          <.button :if={@live_action == :new} phx-disable-with="Saving...">Invite member</.button>
          <.button :if={@live_action == :edit} phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset =
      Accounts.change_user_registration(user)
      |> Ecto.Changeset.put_change(:project_ids, Enum.into(user.projects, [], & &1.id))
      |> Ecto.Changeset.put_change(:feature_ids, Enum.into(user.features, [], & &1.id))
      |> Ecto.Changeset.put_change(:environment_ids, Enum.into(user.environments, [], & &1.id))

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    user_params =
      Map.put(user_params, "full_access", user_params["full_access"] == "on" && true)

    changeset =
      socket.assigns.user
      |> SavvyFlags.Accounts.User.invitation_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params =
      user_params
      |> Map.put("full_access", user_params["full_access"] == "on" && true)

    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.invite_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        Accounts.deliver_user_invitation_instructions(
          user,
          &url(~p"/users/invitation/#{&1}")
        )

        {:noreply,
         socket
         |> put_flash(:info, "User invited successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent({key, user}) do
    user = SavvyFlags.Repo.preload(user, [:projects, :environments, :features])
    send(self(), {__MODULE__, {key, user}})
  end
end
