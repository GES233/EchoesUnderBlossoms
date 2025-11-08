defmodule HanaShirabeWeb.MemberLive.Registration do
  @moduledoc """
  注册用户。

  TODO：

  * 考虑语言选择
  * 考虑邀请制
  """
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts
  alias HanaShirabe.Accounts.Member

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <%= if !@member_email do %>
            <.header>
              {dgettext("account", "Register for an account")}
              <:subtitle>
                {dgettext("account", "Already registered? %{login_link} to your account now.",
                  login_link: translate_with_link(%{url: ~p"/login"})
                )
                |> raw()}
              </:subtitle>
            </.header>
          <% else %>
            <.header>
              {dgettext("account", "Confirm")}
              <:subtitle>
                <!---->
                {dgettext("account", "You can use magic link to comfirm and login you account.")}
              </:subtitle>
            </.header>
          <% end %>
        </div>

        <%= if !@member_email do %>
          <.form
            :let={f}
            :if={!@member_email}
            for={@sign_up_form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
          >
            <div phx-hook=".LocaleFormInput" id="locale-toggle">
              <.input
                field={f[:prefer_locale]}
                type="select"
                label={gettext("Locale Preference")}
                options={[
                  {"English", "en"},
                  {"日本語", "ja"},
                  {"简体中文", "zh_Hans"}
                ]}
                phx-change={JS.push("locale_changed")}
              />
              <script :type={Phoenix.LiveView.ColocatedHook} name=".LocaleFormInput">
                export default {
                  mounted() {
                    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

                    this.handleEvent("set_locale_cookie", ({ locale }) => {
                      fetch(`/set-locale/${locale}`, {
                        method: "POST",
                        headers: {
                          "x-csrf-token": csrfToken
                        }
                      }).then(response => {
                        if (response.ok) {
                          this.pushEvent("locale_cookie_updated", {locale: locale});
                      }}).catch(error => {
                        console.error(`Failed to set locale cookie to '${locale}':`, error)
                      });
                    });
                  }
                }
              </script>
            </div>

            <.input
              field={f[:nickname]}
              type="text"
              label={dgettext("account", "Nickname")}
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
              placeholder={dgettext("account", "Tell us how we should address you.")}
            />
            <.input
              field={f[:email]}
              type="email"
              label={dgettext("account", "Email")}
              autocomplete="email"
              required
              phx-mounted={JS.focus()}
              placeholder={
                dgettext("account", "Please enter your email address so we can contact you.")
              }
            />
            <!-- 放个将要成为邀请码的 .iuput 在这里 -->
            <.button
              phx-disable-with={dgettext("account", "Creating account...")}
              class="btn btn-primary w-full"
            >
              {dgettext("account", "Create an account")}
            </.button>
          </.form>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # 这个函数是为了解决操蛋的
  # Already registered? <link>Log in</link> to your account now.
  # =>
  # 已经登录了？那就<link>登录</link> 。
  # 的问题
  # 参见 https://elixirforum.com/t/gettext-html-in-translation/14889/5
  defp translate_with_link(assigns) do
    ~H"""
    <.link navigate={@url} class="font-semibold text-brand hover:underline">
      {dgettext("account", "Log in")}
    </.link>
    """
    |> Phoenix.HTML.Safe.to_iodata()
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{member: member}}} = socket)
      when not is_nil(member) do
    {:ok, redirect(socket, to: HanaShirabeWeb.MemberAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.Member.registration_changeset(%Member{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset) |> assign(member_email: nil),
     temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event(
        "locale_changed",
        %{
          "_target" => ["registration_form", "prefer_locale"],
          "registration_form" => %{"prefer_locale" => locale}
        },
        socket
      ) do
    Gettext.put_locale(HanaShirabeWeb.Gettext, locale)

    # 此功能的测试代码仅需要考虑 Cookie 的更新就可以了
    socket = push_event(socket, "set_locale_cookie", %{locale: locale})

    {:noreply, socket}
  end

  # 因为 LiveWiew 底层 Socket 的属性
  # 以及更换语言这么一种「全局」的动作
  # 就意味着没有办法通过 Phoenix.LiveView 的方式解决
  # 只能用一个这种很不优雅的形式实现
  # 私密马赛
  def handle_event("locale_cookie_updated", %{"locale" => locale}, socket) do
    # 为了那条 flash 消息
    Gettext.put_locale(locale)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Locale updated!"))
     |> redirect(to: ~p"/sign_up", replace: true)}
  end

  def handle_event("save", %{"registration_form" => member_params}, socket) do
    audit_log = socket.assigns[:audit_log]

    # 如果需要邀请码，这里要在加一组
    do_register(audit_log, member_params, socket)
  end

  def handle_event("validate", %{"registration_form" => member_params}, socket) do
    changeset =
      Accounts.Member.registration_changeset(%Member{}, member_params, validate_unique: false)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("submit_code", _params, socket) do
    {:noreply, assign(socket, trigger_submit: true)}
  end

  defp do_register(audit_log, member_params, socket) do
    case Accounts.register_member(audit_log, member_params) do
      {:ok, member} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            member,
            &url(~p"/login/#{&1}")
          )

        {
          :noreply,
          socket
          |> put_flash(
            :info,
            dgettext(
              "account",
              "An email was sent to %{member_email}, please access it to confirm your account.",
              member_email: member.email
            )
          )
          |> assign(member_email: member.email)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form =
      if locale = socket.assigns[:locale] do
        Ecto.Changeset.put_change(changeset, :prefer_locale, locale)
      else
        changeset
      end
      |> to_form(as: "registration_form")

    assign(socket, sign_up_form: form)
  end
end
