import Config

# 配置你的数据库
config :hana_shirabe, HanaShirabe.Repo,
  database: Path.expand("../hana_shirabe_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# 我们在开发时禁用缓存，并且启用 debug 以及代码重载。
#
# 观察者配置可用于运行应用程序的外部观察者。例如，我们可以用它来捆绑 .js 和 .css 源。
config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  # 绑定到环回 IPv4 地址可防止其他机器访问。
  # 如果想要从其他机器访问请改成 `ip: {0, 0, 0, 0}` 。
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "8847")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "knRu+FvdGCuxuCUBBzRwO1HACUVisCUm8tb2yIuu9KwutIP3616NuYPDz/dT9Nxu",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:hana_shirabe_web, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:hana_shirabe_web, ~w(--watch)]}
  ]

# ## SSL 支持
#
# 为了在开发过程中使用 HTTPS，可通过运行以下 Mix 任务生成自签名证书：
#
# mix phx.gen.cert
#
# 运行 `mix help phx.gen.cert` 获取更多信息。
#
# 上面的 `http:` 配置可替换为
#
#   https: [
#     port： 4001,
#     cipher_suite: :strong,
#     keyfile: "priv/cert/selfsigned_key.pem",
#     certfile: "priv/cert/selfsigned.pem"
#   ],
#
# 如果需要，可配置 `http:` 和 `https:` 密钥，以便在不同端口上运行 http 和 https 服务器。

# 为浏览器端的重载监视静态资源与模板。
config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/hana_shirabe_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# 启用开发路由下的控制板和邮箱（邮箱我没用）
config :hana_shirabe_web, dev_routes: true

# 启用开发路由下的控制板和邮箱（邮箱我没用）
config :logger, :default_formatter, format: "[$level] $message\n"

# 为加快开发环境的编译在运行时初始化 plug
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # 将 HEEx 调试注释作为 HTML 注释包含在渲染的标记中
  # 更改此配置将需要 mix clean 和完全重新编译。
  debug_heex_annotations: true,
  debug_attributes: true,
  # 启用有用但可能昂贵的运行时检查
  enable_expensive_runtime_checks: true

# 仅在生产环境开始 swoosh api client 。
config :swoosh, :api_client, false

# 在开发环境设置更高的栈跟踪。但是在生产中不要这么设置，因为性能开销太大。
config :phoenix, :stacktrace_depth, 20
