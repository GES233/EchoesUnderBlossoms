defmodule HanaShirabeWeb.MemberLive.Settings do
  # 主要是修改昵称、简介等不敏感信息
  # 和原来的 Settings （现在的 SensitiveSettings 分开）
  use HanaShirabeWeb, :live_view

  on_mount {HanaShirabeWeb.MemberAuth, :require_authenticated}

  # alias HanaShirabe.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          {dgettext("account", "Account Settings")}
          <:subtitle>{dgettext("account", "Manage your your basic information")}</:subtitle>
        </.header>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
