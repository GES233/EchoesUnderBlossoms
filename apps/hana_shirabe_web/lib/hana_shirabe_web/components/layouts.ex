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
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  用于统一 flash 组内标题和内容的显示。

  ## Examples

      <.flash_group flash={@flash} />
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
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

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
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc"""
  客制化的页面标题。

  本站的标题，一般分为两种情况：

  - 内容为主（比方说网页主要是某歌曲或提案）
    - 其格式为 `{page_title} - SiteName`
  - 功能为主（注册、登录、首页等等）
    - 其格式为 `SiteName :: {page_role}`

  当然还有另一种情况，没有其他信息。那么就是
  `SiteName - Description` 。

  ## Examples

      <.naive_title title_or_role={fn -> gettext("SignUp") end} />
      <.naive_title title_or_role={assigns[:page_title]} />
  """
  attr :title_or_role, :any, required: true, doc: "Content rendered inside the `title` tag."

  def naive_title(assigns) do
    ~H"""
    <%= cond do %>
      <% is_function(@title_or_role, 0) -> %> <!-- Role -->
        <.live_title prefix={gettext("Echoes Under Blossoms") <> " :: "}>
          {@title_or_role.()}
        </.live_title>
      <% is_binary(@title_or_role) -> %> <!-- Title -->
        <.live_title suffix={" - " <> gettext("Echoes Under Blossoms")}>
          {@title_or_role}
        </.live_title>
      <% true -> %> <!-- Other situation -->
        <.live_title default={gettext("Echoes Under Blossoms")}>
        </.live_title>
    <% end %>
    """
  end
end
