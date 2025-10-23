defmodule HanaShirabeWeb do
  @moduledoc """
  定义网络界面（如控制器、组件、通道等）的入口点。

  可在应用程序中通过以下方式被调用：

      use HanaShirabeWeb, :controller
      use HanaShirabeWeb, :html

  下面的定义将在每个控制器、组件等中执行，因此要简洁明了，重点放在 import 、 use 以及 alias 上。

  【请不要】在下面的 quote 表达式内定义函数。相反，请定义附加模块并在此处导入这些模块。
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # 导入管线中共同的 Conn 以及 controller 的函数
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: HanaShirabeWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # 翻译
      use Gettext, backend: HanaShirabeWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import HanaShirabeWeb.CoreComponents

      # 模板用的通用模块
      alias Phoenix.LiveView.JS
      alias HanaShirabeWeb.Layouts

      # 路由需要用的 ~p 魔符
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HanaShirabeWeb.Endpoint,
        router: HanaShirabeWeb.Router,
        statics: HanaShirabeWeb.static_paths()
    end
  end

  @doc """
  用啥功能调啥名
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
