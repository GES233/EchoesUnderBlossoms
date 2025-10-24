import Config

# config/runtime.exs 在所有环境下都会被执行，包括在发布过程中。
# 它在编译后在系统启动前的这段时间执行，因此通常用于从环境变量或其他地方加载
# 生产配置和秘密。不要在这里定义任何编译时配置，因为它们不会被应用。
# 下面的代码块包含生产环境的运行时配置。
if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/hana_shirabe/hana_shirabe.db
      """

  config :hana_shirabe, HanaShirabe.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # 密钥库用于签署/加密 cookie 和其他秘密。 config/dev.exs 和 config/test.exs
  # 中使用的是默认值，但你想在生产环境中使用不同的值，而且你很可能不想在版本控制中出现
  # 该值，因此我们使用环境变量来代替。
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
    http: [
      # 启用 IPv6 且绑定所有接口。
      # 如果只想要本地访问请改成 {0, 0, 0, 0, 0, 0, 0, 1} 。
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## 使用版本
  #
  # 如果要进行 OTP 发布，则需要指示 Phoenix 启动每个相关端点：
  #
  #     config :hana_shirabe_web, HanaShirabeWeb.Endpoint, server: true
  #
  # 然后，你就可以调用 `mix release` 来组装发布。请参阅
  # `mix help release` 获取更多信息。

  # ## SSL 支持
  #
  # 要使 SSL 正常工作，您需要将 "https" 密钥添加到端点配置中：
  #
  #     config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # `cipher_suite` 设置为 `:strong`，以仅支持最新且更安全的 SSL 密码。
  # 这意味着旧版浏览器和客户端可能不受支持。您可以将其设置为
  # `:compatible`，以获得更广泛的支持。
  #
  # `:keyfile` 以及 `:certfile` 预期为可访问到磁盘中对应文件的
  # 【绝对目录】或是相对于 `/priv` 的【相对目录】，比方说
  # "priv/ssl/server.key" 。对于所有支持 SSL 配置的选项，可以参考
  # https://hexdocs.pm/plug/Plug.SSL.html#configure/1 。
  #
  # 此外我们推荐在你的 config/prod.exs 里设置 `force_ssl` ，
  # 确认所有通过 http 协议的数据都会被重定向为 https ：
  #
  #     config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # 查看 `Plug.SSL` 的文档可以获取 `force_ssl` 中所有的可选选项。

  # ## 配置邮箱
  #
  # 生产环境下你需要配置邮箱以使用不同的适配器。
  # 这里是一个 Mailgun 的示例配置：
  #
  #     config :hana_shirabe, HanaShirabe.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # 绝大多数 非SMTP 的适配器需要一个 API 客户端。Swoosh 对 Req 、
  # Hackney 以及 Finch 提供开箱即用的支持。此配置在编译时间被执行的
  # config/prod.exs 中进行：
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # 查看 https://hexdocs.pm/swoosh/Swoosh.html#module-installation 获取详情。

  config :hana_shirabe, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
