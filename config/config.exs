# 通过 Config 模块的帮助，这个文件负责配置你的伞项目以及【所有的应用】
# 以及其依赖。
#
# 请注意，伞项目中的所有应用程序都共享相同的配置和依赖关系，这也是它们使用
# 相同配置文件的原因。如果你希望每个应用程序有不同的配置或依赖关系，最好将
# 这些应用程序移出保护伞。
import Config

# 配置 Mix 任务以及生成器
config :hana_shirabe,
  ecto_repos: [HanaShirabe.Repo]

# 配置邮件程序
#
# 默认情况下，它使用 "本地" 适配器，将邮件存储在本地。您可以在浏览器中的 "/dev/mailbox" 查看邮件。
#
# 对于生产环境，建议在 "config/runtime.exs" 文件中配置其他适配器。
config :hana_shirabe, HanaShirabe.Mailer, adapter: Swoosh.Adapters.Local

config :hana_shirabe_web,
  ecto_repos: [HanaShirabe.Repo],
  generators: [context_app: :hana_shirabe]

# 配置端点
config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HanaShirabeWeb.ErrorHTML, json: HanaShirabeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HanaShirabe.PubSub,
  live_view: [signing_salt: "iy2RPlu8"]

# 配置 esbuild （需要版本号）
config :esbuild,
  version: "0.25.4",
  hana_shirabe_web: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/hana_shirabe_web/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# 配置 tailwind （需要版本号）
config :tailwind,
  version: "4.1.7",
  hana_shirabe_web: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/hana_shirabe_web", __DIR__)
  ]

# 配置 Elixir 日志
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# 在 Phoenix 中使用 Jason 来解析 JSON
config :phoenix, :json_library, Jason

# 将简体中文设置为缺省语言
# config :gettext,
#   default_locale: "zh_CN",
#   locales: ~w(en zh_CN)

# 依据环境导入不同的配置。这一行必须在文件的最后
# 因此其可以覆写上面所有的默认配置。
import_config "#{config_env()}.exs"
