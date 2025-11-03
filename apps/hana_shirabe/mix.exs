defmodule HanaShirabe.MixProject do
  use Mix.Project

  def project do
    [
      app: :hana_shirabe,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {HanaShirabe.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:dns_cluster, "~> 0.2.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:pbkdf2_elixir, "~> 2.0"},
      # {:argon2_elixir, "~> 4.0"},
      # 在 HanaShirabe 中多个模块被使用以支援多语言翻译
      # （这里就是使用 Umbrella Application 的特点了）
      # 至于我什么要选择 Umbrella 是因为后续应用的复杂度
      # 肯定可以用得上（只要社区可以正常运营下去的话）
      {:gettext, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run #{__DIR__}/priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "gettext.update": [
        "gettext.extract",
        "gettext.merge priv/gettext --locale ja",
        "gettext.merge priv/gettext --locale zh_Hans"
      ],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
