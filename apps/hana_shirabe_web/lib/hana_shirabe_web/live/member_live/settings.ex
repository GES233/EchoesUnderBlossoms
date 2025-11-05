defmodule HanaShirabeWeb.MemberLive.Settings do
  # 主要是修改昵称、简介等不敏感信息
  # 和原来的 Settings （现在的 SensitiveSettings 分开）
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            {dgettext("account", "Account Settings")}
            <:subtitle>{dgettext("account", "Manage your your basic information.")}</:subtitle>
          </.header>
        </div>

        <.form :let={f} for={@form} id="settings_form" phx-submit="update_info" phx-change="validate">
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

        <div class="divider">{dgettext("account", "Dangerours Zone")}</div>

        <div class="text-center">
          {dgettext(
            "account",
            "If you want to update your email address or password, please enter %{sensitive_settings}.",
            sensitive_settings: translate_senaitive_settings(%{url: ~p"/me/sensitive-settings"})
          )
          |> raw()}
        </div>
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
       form: to_form(Accounts.Member.profile_changeset(current_member, %{}), as: "settings_form")
     )}
  end

  @impl true
  def handle_event("validate", unsigned_params, socket) do
    unsigned_params |> IO.inspect(label: :validate)

    {:noreply, socket}
  end

  def handle_event("update_info", unsigned_params, socket) do
    # audit_log = socket.assigns[:audit_log]

    unsigned_params |> IO.inspect(label: :update_info)

    {:noreply, socket}
  end
end
