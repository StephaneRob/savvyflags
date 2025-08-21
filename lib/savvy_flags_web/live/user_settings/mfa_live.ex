defmodule SavvyFlagsWeb.UserSettings.MfaLive do
  use SavvyFlagsWeb, :live_view
  alias SavvyFlags.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="text-center mb-6">
      MFA Setup
      <:subtitle>Setup your 2FA to protect your account</:subtitle>
    </.header>

    <div class="w-1/2 mx-auto">
      <div class="mb-4 flex justify-center p-4 border border-neutral-200 bg-white rounded">
        {raw(@qr_code)}
      </div>
      <p>
        <span class="font-bold">Step 1:</span>
        To set up your multi-factor authentication, scan the QR code above (or enter the uri below in your authenticator app).
      </p>
      <p class="my-5">
        <span class="font-bold">Secret uri</span>
      </p>
      <p class="mb-4">
        <.copy_to_clipboard value={@uri} id="mfa_uri" class="font-mono text-gray-600 text-sm" />
      </p>
      <p class="mb-5">
        <span class="font-bold ">Step 2:</span>
        Once you've scanned the QR code or entered the secret URI, complete the set up by entering the code listed in your authenticator
      </p>
      <form :if={!@show_recovery_codes} phx-submit="check">
        <.input
          type="text"
          id="code"
          name="code"
          value=""
          label="Code"
          autocomplete="off"
          disabled={@show_recovery_codes}
        />
        <p :if={@error_code} class="text-sm text-red-800">Code incorrect please retry</p>
        <.button class="mt-5">Verify</.button>
      </form>
      <div :if={@show_recovery_codes} class="mt-4">
        <p class="font-bold mb-4">
          <.icon name="hero-check-circle-solid" class="ml-1 h-5 w-5 text-green-400" />
          You've successfully enabled MFA please copy your recovery codes
        </p>
        <p class="mb-5">
          <span class="font-bold ">Step 3:</span>
          Copy MFA recovery codes and keep them safe. If you cannot access your MFA device, you can log in using one of these recovery codes. Each code can be used only once.
        </p>
        <p class="font-bold">Recovery codes</p>
        <ul class="border rounded-sm border-gray-300 bg-white p-4 mb-5">
          <li :for={code <- @recovery_codes}>{code}</li>
        </ul>
        <.link navigate={~p"/users/settings"}>
          <.button>Complete !</.button>
        </.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    current_user = socket.assigns.current_user
    secret = NimbleTOTP.secret()
    uri = NimbleTOTP.otpauth_uri(current_user.reference, secret, issuer: "SavvyFlags")

    {:ok, qr_code} =
      uri
      |> QRCode.create()
      |> QRCode.render(:svg, %QRCode.Render.SvgSettings{scale: 4})

    socket
    |> assign(:uri, uri)
    |> assign(:secret, secret)
    |> assign(:error_code, false)
    |> assign(:show_recovery_codes, false)
    |> assign(:recovery_codes, for(_ <- 1..10, do: generate_code()))
    |> assign(:qr_code, qr_code)
    |> ok()
  end

  @impl true
  def handle_event("check", %{"code" => code}, socket) do
    current_user = socket.assigns.current_user
    secret = socket.assigns.secret
    recovery_codes = socket.assigns.recovery_codes

    socket =
      with true <- NimbleTOTP.valid?(secret, code),
           {:ok, _} <- Accounts.update_user_mfa(current_user, secret, recovery_codes) do
        socket
        |> assign(:error_code, false)
        |> assign(:show_recovery_codes, true)
      else
        _ ->
          socket
          |> assign(:error_code, true)
          |> assign(:show_recovery_codes, false)
      end

    noreply(socket)
  end

  defp generate_code do
    random = :crypto.strong_rand_bytes(32)

    :md5
    |> :crypto.hash(random)
    |> Base.encode32(padding: false)
    |> String.slice(0..10)
  end
end
