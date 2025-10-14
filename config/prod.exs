import Config

# 请注意，我们还包含了缓存清单的路径，其中包含静态文件的 digested version 。
# 该清单由 `mix phx.digest` 任务生成，应在生成静态文件后、
# 启动生产服务器之前运行该任务。
config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# 配置 Swoosh API Client
config :swoosh, :api_client, Swoosh.ApiClient.Req

# 禁用 Swoosh 本地存储
config :swoosh, local: false

# 生产环境下不要输出 debug 信息
config :logger, level: :info

# 运行时配置，包括读取环境变量的部分，在 config/runtime.exs 中。
