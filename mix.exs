defmodule HanaShirabe.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # 依赖项可以是 Hexpm 上的包：
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # 也可以是 Git 仓库或本地地址：
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # 输入 "mix help deps" 可获得更多范例与选项。
  #
  # 此处列出的依赖项仅适用于项目的根目录，无法从 apps/ 文件夹内的应用程序访问。
  # 结合里边的注释，就是说在这里的依赖项是针对整个应用而非里边的某个应用的，
  # 也就是说，如果里边的某个应用有用到的话，那么需要在里边的 `mix.exs` 再导入一遍。
  defp deps do
    [
      # 需要运行 "mix format" 来针对位于伞项目根目录其他的 ~H 或 .heex 文件进行格式化
      {:phoenix_live_view, ">= 0.0.0"}
    ]
  end

  # 别名（Alias）是专门用于当前项目的快捷方式或任务。
  # 比方说，安装项目的依赖以及运行其他的安装步骤，可以运行：
  #
  #     $ mix setup
  #
  # 有关别名的更多信息，请参阅 `Mix` 的文档。
  #
  # 此处列出的别名仅适用于项目的根目录，无法从 apps/ 文件夹内的应用程序访问。
  defp aliases do
    [
      # 在所有的子应用中运行 `mix setup`
      setup: ["cmd mix setup"],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
