defmodule HanaShirabeWeb.Layouts do
  @moduledoc """
  该模块包含应用的布局和相关功能。
  """
  use HanaShirabeWeb, :html

  # 将 layouts/* 中的所有文件嵌入此模块。
  # 默认的 root.html.heex 文件包含应用程序的 HTML 框架，即 HTML 标头和其他静态内容
  embed_templates "layouts/*"

  @doc """
  渲染应用的整体布局。

  此函数通常由每个模板调用，它通常包含应用程序的 menu 或 sidebar
  或巴拉巴拉。

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="bg-base-100/80 backdrop-blur-sm sticky top-0 z-10">
      <nav class="navbar px-4 sm:px-6 lg:px-8">
        <div class="navbar-start">
          <a href={~p"/"} class="btn btn-ghost text-xl">⍼</a>
        </div>

        <div class="navbar-end">
          <div class="hidden sm:flex items-center gap-4">
            <%= if @current_scope do %>
              <!-- TODO: 如果可以的话改成下拉列表 -->
              <span class="text-sm font-medium text-base-content/80">
                {@current_scope.member.nickname}
              </span>
              <.link
                href={~p"/me/settings"}
                class="text-sm font-semibold leading-6 text-base-content/70"
              >
                {dgettext("account", "Settings")}
              </.link>
              <.link
                href={~p"/logout"}
                method="delete"
                class="text-sm font-semibold leading-6 text-base-content/70"
              >
                {dgettext("account", "Log out")}
              </.link>
            <% else %>
              <.link
                href={~p"/sign_up"}
                class="text-sm font-semibold leading-6 text-base-content/70"
              >
                {dgettext("account", "Register")}
              </.link>
              <.link
                href={~p"/login"}
                class="text-sm font-semibold leading-6 text-base-content/70"
              >
                {dgettext("account", "Log in")}
              </.link>
            <% end %>
          </div>
          <.theme_toggle />
        </div>
      </nav>
    </header>
    <div class="sticky top-16 z-20 px-4 sm:px-6 lg:px-8"><.flash_group flash={@flash} /></div>

    <main class="relative isolate">{render_slot(@inner_block)}</main>

    <footer class="mt-16 border-t py-8">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <p class="text-center text-sm text-base-content">{copyleft_declaration(%{})}</p>
      </div>
    </footer>
    """
  end

  defp copyleft_declaration(assigns) do
    ~H"""
    🄯 {DateTime.utc_now().year}
    <.link class="text-sm font-semibold" href="https://github.com/GES233/EchoesUnderBlossoms">
      {gettext("Echoes Under Blossoms")}
    </.link>
    {gettext("The copyright of user-generated content on this site belongs to the individual user.")}
    """
  end

  @doc """
  用于统一 flash 组内标题和内容的显示。

  ## Examples <.flash_group flash={@flash} />
  """

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  根据 app.css 中定义的主题，提供深色/浅色主题切换。

  请参阅 root.html.heex 中的 `<head>` 部分，该部分会在页面加载前应用主题。
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=core-cream-soup]_&]:left-1/3 [[data-theme=noctilucent]_&]:left-2/3 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="core-cream-soup"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="noctilucent"
      >
        <.icon name="hero-sparkles-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
