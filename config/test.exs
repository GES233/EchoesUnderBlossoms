import Config

# 只在测试环境里这么做，因为降低复杂度节省时间
config :pbkdf2_elixir, t_cost: 1, m_cost: 8

# 配置你的数据库
#
# 为了提供 CI 环境下内建测试分区，
# MIX_TEST_PARTITION 环境变量会被使用。
# 运行 `mix help test` 可获得更多信息。
config :hana_shirabe, HanaShirabe.Repo,
  database: Path.expand("../hana_shirabe_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :hana_shirabe, HanaShirabe.Accounts,
  totp_secret_key_salt: "lWYpML2HI6PwfDMAx2PJnrpGDVV6v2HSARTXY5Lp/bRUOWyMJlyio8yWIlM7dduc"

# 我们不需要在测试时运行服务器。
# 如果需要的话，可以启用下面的 `server` 选项。
config :hana_shirabe_web, HanaShirabeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XweDedO2shmtDTrotxUVfYjyzBJoR1nlCUOJXrb+4BtgvkmBb3W/fvFLq24nlawt",
  server: false

# 在测试时只需要输出警告和错误信息
config :logger, level: :warning

# 测试环境无需发送邮件
config :hana_shirabe, HanaShirabe.Mailer, adapter: Swoosh.Adapters.Test

# 禁用 Swoosh API 客户端，其只被生产适配器所需要
config :swoosh, :api_client, false

# 在运行时初始化 plug ，以加快测试编译速度
config :phoenix, :plug_init_mode, :runtime

# 启用有用但可能昂贵的运行时检查
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
