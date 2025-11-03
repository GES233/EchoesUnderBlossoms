defmodule HanaShirabeWeb.MemberLive.Confirmation do
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            {dgettext("account", "Welcome %{member_email}", member_email: @member.email)}
          </.header>
        </div>
        
        <.form
          :if={!@member.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/login?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with={dgettext("account", "Confirming...")}
            class="btn btn-primary w-full"
          >
            {dgettext("account", "Confirm and stay logged in")}
          </.button>
          <.button
            phx-disable-with={dgettext("account", "Confirming...")}
            class="btn btn-primary btn-soft w-full mt-2"
          >
            {dgettext("account", "Confirm and log in only this time")}
          </.button>
        </.form>
        
        <.form
          :if={@member.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/login"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button
              phx-disable-with={dgettext("account", "Logging in...")}
              class="btn btn-primary w-full"
            >
              Log in
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with={dgettext("account", "Logging in...")}
              class="btn btn-primary w-full"
            >
              {dgettext("account", "Keep me logged in on this device")}
            </.button>
            <.button phx-disable-with="Logging in..." class="btn btn-primary btn-soft w-full mt-2">
              {dgettext("account", "Log me in only this time")}
            </.button>
          <% end %>
        </.form>
        
        <p :if={!@member.confirmed_at} class="alert alert-outline mt-8">
          {dgettext(
            "account",
            "Tip: If you prefer passwords, you can enable them in the member settings."
          )}
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if member = Accounts.get_member_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "member")

      {:ok, assign(socket, member: member, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      err_msg = dgettext("account", "Magic link is invalid or it has expired.")

      {:ok,
       socket
       |> put_flash(:error, err_msg)
       |> push_navigate(to: ~p"/login")}
    end
  end

  @impl true
  def handle_event("submit", %{"member" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "member"), trigger_submit: true)}
  end
end
