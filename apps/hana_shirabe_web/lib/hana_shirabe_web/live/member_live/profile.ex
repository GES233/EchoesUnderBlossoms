defmodule HanaShirabeWeb.MemberLive.Profile do
  @moduledoc """
  展示以及修改用户简介。

  ## 功能

  主要是修改昵称、语言偏好、简介等不敏感信息。

  和注册页（`HanaShirabeWeb.MemberLive.Registration`）不同，
  为保证数据的一致性，并未实现更换语言的重载。

  ## 页面

  ### 页面

  默认展示用户信息，点击按钮后切换到更改表单。

  ### `profile_form` 表单

  包含对昵称、语言以及简介的修改。

  修改信息触发 `validate` 事件，提交表单触发 `update_info` 事件。

  ### 跳转链接

  对邮件、密码的修改需要跳转。
  """
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts

  import HanaShirabeWeb.Hana.MemberProfile, only: [show_member: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <%= if @update do %>
          <div class="text-center">
            <.header>
              {dgettext("account", "Account Profile")}
              <:subtitle>{dgettext("account", "Manage your your basic information.")}</:subtitle>
            </.header>
          </div>

          <.form :let={f} for={@form} id="profile_form" phx-submit="update_info" phx-change="validate">
            <.input
              field={f[:nickname]}
              label={dgettext("account", "Nickname")}
              autocomplete="username"
              phx-mounted={JS.focus()}
            />
            <.input
              type="select"
              field={f[:prefer_locale]}
              label={gettext("Locale Preference")}
              options={[
                {"English", "en"},
                {"日本語", "ja"},
                {"简体中文", "zh_Hans"}
              ]}
            />
            <.input
              field={f[:intro]}
              type="textarea"
              label={dgettext("account", "Introduction")}
              autocomplete=""
              phx-mounted={JS.focus()}
            />
            <.button
              class="btn btn-primary w-full"
              phx-disable-with={dgettext("account", "Updating...")}
            >
              {dgettext("account", "Update Profile")}
            </.button>
          </.form>

          <.button
            phx-click="toggle_update"
            phx-disable-with={gettext("Loading...")}
            class="btn btn-secondary w-full"
          >
            {gettext("Cancel")}
          </.button>
          <div class="divider">{dgettext("account", "Danger Zone")}</div>

          <div class="text-center">
            {dgettext(
              "account",
              "If you want to update your email address or password, please enter %{sensitive_settings}.",
              sensitive_settings: translate_senaitive_settings(%{url: ~p"/me/sensitive-settings"})
            )
            |> raw()}
          </div>
        <% else %>
          <div class="text-center">
            <.header>
              {dgettext("account", "Account Profile")}
              <:subtitle>{dgettext("account", "Your personal profile page.")}</:subtitle>
            </.header>
          </div>

          <.show_member member={@current_scope.member}>
            <.button
              phx-click="toggle_update"
              phx-disable-with={gettext("Loading...")}
              class="btn btn-primary"
            >
              {dgettext("account", "Edit Profile")}
            </.button>
          </.show_member>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp translate_senaitive_settings(assigns) do
    ~H"""
    <.link
      navigate={@url}
      class="font-semibold text-brand hover:underline"
      phx-no-format
    >
      {dgettext("account", "Account Sensitive Settings")}
    </.link>
    """
    |> Phoenix.HTML.Safe.to_iodata()
  end

  @impl true
  def mount(_params, _session, socket) do
    current_member = socket.assigns.current_scope.member

    {:ok,
     assign(socket,
       update: false,
       form: to_form(Accounts.Member.profile_changeset(current_member, %{}), as: "profile_form")
     )}
  end

  @impl true
  def handle_event("validate", %{"profile_form" => unsigned_params}, socket) do
    current_member = socket.assigns.current_scope.member

    form =
      current_member
      |> Accounts.Member.profile_changeset(unsigned_params)
      |> Map.put(:action, :valudate)
      |> to_form(as: "profile_form")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("toggle_update", _params, socket) do
    # 确保取消编辑时，表单的脏数据不会影响展示
    current_member = socket.assigns.current_scope.member

    form =
      current_member
      |> Accounts.Member.profile_changeset(%{})
      |> to_form(as: "profile_form")

    {:noreply,
     socket
     |> assign(
       # 进行一个 update 的 tuggle
       update: !socket.assigns.update,
       form: form
     )}
  end

  def handle_event("update_info", %{"profile_form" => unsigned_params}, socket) do
    audit_log = socket.assigns.current_scope.audit_context
    current_member = socket.assigns.current_scope.member

    {:noreply, do_update_profile(audit_log, current_member, unsigned_params, socket)}
  end

  defp do_update_profile(audit_log, member_before_update, unsigned_params, socket) do
    case Accounts.update_member_profile(audit_log, member_before_update, unsigned_params) do
      {:ok, new_member} ->
        socket
        |> put_flash(:info, gettext("Profile updated!"))
        # |> redirect(to: ~p"/me/profile", replace: true)
        |> assign(
          update: false,
          # 更新 current_scope 中的 member，让 show_member 组件立刻显示新数据
          current_scope: %{socket.assigns.current_scope | member: new_member}
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        changeset |> to_form(as: "profile_form") |> then(&assign(socket, form: &1))
    end
  end
end
