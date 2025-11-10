defmodule HanaShirabeWeb.MemberLive.Login do
  @moduledoc """
  登录页面。

  ## 功能

  实现登录（网页端）。

  ## 页面

  ### 基于邮件的表单（`email_login_form`）

  表单存在两阶段，阶段一只有地址，阶段二存在邮件以及验证码，
  也可以通过验证码登录。

  ### 基于邮件以及密码的表单（`password_login_form`）

  ### 表单提交

  `trigger_submit_code: true`，数据走 Controller 。
  """
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>{dgettext("account", "Log in")}</p>

            <:subtitle>
              <%= if @current_scope do %>
                {dgettext(
                  "account",
                  "You need to reauthenticate to perform sensitive actions on your account."
                )}
              <% else %>
                {dgettext("account", "Don't have an account? %{sign_up_link} for an account now.",
                  sign_up_link: translate_sign_up_instruction(%{url: ~p"/sign_up"})
                )
                |> raw()}
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>{dgettext("account", "You are running the local mail adapter.")}</p>

            <p>
              {dgettext("account", "To see sent emails, visit %{email_page}.",
                email_page: translate_email_instructions(%{})
              )
              |> raw()}
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@magic_form}
          id="email_login_form"
          action={~p"/login"}
          phx-submit={if !@enter_code, do: "submit_mail", else: "submit_code"}
          phx-trigger-action={@trigger_submit_code}
        >
          <.input
            readonly={!!@current_scope || @enter_code}
            field={f[:email] || @email}
            type="email"
            label={dgettext("account", "Email")}
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            :if={@enter_code}
            field={f[:code]}
            type="text"
            label={dgettext("account", "Verification Code")}
            autocomplete="one-time-code"
            required
            inputmode="numeric"
            pattern="[0-9]*"
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            <%= if !@enter_code do %>
              {dgettext("account", "Send code")}
            <% else %>
              {dgettext("account", "Log in with email")}
            <% end %>
            <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">{dgettext("account", "or")}</div>

        <.form
          :let={f}
          for={@password_form}
          id="password_login_form"
          action={~p"/login"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label={dgettext("account", "Email")}
            autocomplete="username"
            required
          />
          <.input
            field={f[:password]}
            type="password"
            label={dgettext("account", "Password")}
            autocomplete="current-password"
          />
          <.button class="btn btn-primary w-full" name={f[:remember_me].name} value="true">
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

  defp translate_sign_up_instruction(assigns) do
    ~H"""
    <.link
      navigate={@url}
      class="font-semibold text-brand hover:underline"
      phx-no-format
    >{dgettext("account", "Sign up")}</.link>
    """
    |> Phoenix.HTML.Safe.to_iodata()
  end

  defp translate_email_instructions(assigns) do
    ~H"""
    <.link href="/dev/mailbox" class="underline">{dgettext("account", "the mailbox page.")}</.link>
    """
    |> Phoenix.HTML.Safe.to_iodata()
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:member), Access.key(:email)])

    socket =
      socket
      |> assign(
        email: email,
        enter_code: nil,
        magic_form: to_form(%{"email" => email, "code" => nil}, as: "email_login_form"),
        password_form: to_form(%{"email" => email, "password" => nil}, as: "password_login_form"),
        trigger_submit: false,
        trigger_submit_code: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_mail", %{"email_login_form" => %{"email" => email}}, socket) do
    if member = Accounts.get_member_by_email(email) do
      Accounts.deliver_login_instructions(
        member,
        &url(~p"/login/#{&1}")
      )
    end

    info =
      dgettext(
        "account",
        "If your email is in our system, you will receive instructions for logging in shortly."
      )

    {
      :noreply,
      socket
      |> put_flash(:info, info)
      |> assign(
        email: email,
        enter_code: true,
        magic_form: to_form(%{"email" => email, "code" => ""}, as: "email_login_form"),
        password_form: to_form(%{"email" => email, "password" => nil}, as: "password_login_form")
      )
    }
  end

  def handle_event(
        "submit_code",
        %{"email_login_form" => %{"code" => code, "email" => email}},
        socket
      ) do
    member =
      case Accounts.get_member_by_email_magic_link_code(email, code) do
        {member, _} -> member
        _ -> nil
      end

    if is_struct(member) and member.email == email do
      {:noreply, socket |> assign(:trigger_submit_code, true)}
    else
      err_msg = dgettext("account", "Magic link is invalid or it has expired.")

      {:noreply,
       socket
       |> put_flash(:error, err_msg)
       |> push_navigate(to: ~p"/login")}
    end
  end

  defp local_mail_adapter? do
    Application.get_env(:hana_shirabe, HanaShirabe.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
