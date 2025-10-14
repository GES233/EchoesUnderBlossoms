defmodule HanaShirabeWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HanaShirabeWeb.Telemetry,
      # 将你要挂载的进程放在这
      # 通过调用 HanaShirabeWeb.Worker.start_link(arg) 来启动任务
      # 调用的格式是：
      # {HanaShirabeWeb.Worker, arg},

      # 启动响应请求的服务，一般放在最后
      HanaShirabeWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: HanaShirabeWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # 告诉 Phoenix 在应用更新时也更新终端配置。
  @impl true
  def config_change(changed, _new, removed) do
    HanaShirabeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
