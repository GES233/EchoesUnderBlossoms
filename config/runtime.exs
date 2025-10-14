import Config

# config/runtime.exs 在所有环境下都会被执行，包括在发布过程中。
# 它在编译后、系统启动前执行，因此通常用于从环境变量或其他地方加载
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

  # ## SSL Support
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
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## 配置邮箱
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :hana_shirabe, HanaShirabe.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :hana_shirabe, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
