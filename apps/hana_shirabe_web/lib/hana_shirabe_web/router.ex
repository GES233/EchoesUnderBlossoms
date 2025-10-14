defmodule HanaShirabeWeb.Router do
  use HanaShirabeWeb, :router

  import HanaShirabeWeb.MemberAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HanaShirabeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_member
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HanaShirabeWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # 其他 scope 可使用自定义的堆栈。
  # scope "/api", HanaShirabeWeb do
  #   pipe_through :api
  # end

  # 在开发中启用 LiveDashboard 和 Swoosh 邮箱预览
  if Application.compile_env(:hana_shirabe_web, :dev_routes) do
    # 如果想在生产环境中使用 LiveDashboard，则应进行身份验证，且允许管理员访问。
    # 如果应用尚未设置仅限管理员访问的部分，则可以使用 Plug.BasicAuth
    # 设置一些基本身份验证，只要也部署了 SSL（无论如何都应该使用）。
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HanaShirabeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
