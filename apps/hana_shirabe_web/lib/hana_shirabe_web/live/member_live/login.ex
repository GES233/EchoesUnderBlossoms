defmodule HanaShirabeWeb.MemberLive.Login do
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope do %>
                {dgettext("account", "You need to reauthenticate to perform sensitive actions on your account.")}
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/sign_up"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>{dgettext("account", "You are running the local mail adapter.")}</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/login"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">or</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/login"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            {dgettext("account", "Log in and stay logged in")} <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            {dgettext("account", "Log in only this time")}
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:member), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "member")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"member" => %{"email" => email}}, socket) do
    if member = Accounts.get_member_by_email(email) do
      Accounts.deliver_login_instructions(
        member,
        &url(~p"/login/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."
      |> then(dgettext("account", &1))

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/login")}
  end

  defp local_mail_adapter? do
    Application.get_env(:hana_shirabe_web, HanaShirabe.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
