# 为了解决在 Windows 下需要调用 elixir_make 来进行编译的库报错的情况
# 可以参考 https://hexdocs.pm/exqlite/windows.html
# （没错那个 PR 是我提交的）
# 另外关于 `mix.lock` 不规范的报错…
# ~~我再想想办法~~ 等到 ElixirLS 重新运行一遍就可以忽略了
defmodule HanaShirabe.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader],
      dialyzer: [
        # 禁用 Dialyzer 的内联类型检查
        # 要不然 HanaShirabeWeb.Gettext 老是报警告
        #
        # The call 'Elixir.Gettext.Plural':plural
        #    ({<<122,104,95,72,97,110,115>>,
        #      #{'__struct__' => 'Elixir.Expo.PluralForms',
        #        nplurals => 1,
        #        plural => 0}},
        #     _@1 :: any()) does not have a term of type
        #     binary() |
        #     {_,
        #      integer() |
        #      #{'__struct__' := 'Elixir.Expo.PluralForms',
        #        'nplurals' := pos_integer(),
        #        'plural' := 'Elixir.Expo.PluralForms':plural_ast()}} (with opaque subterms) as 1st argument
        #
        # 有没有一种可能：`0` 就在 'Elixir.Expo.PluralForms':plural_ast() 里边？不信看源代码
        #
        # 参见： https://github.com/elixir-lang/elixir/issues/14576 以及
        # https://github.com/erlang/otp/issues/9140
        flags: [:no_opaque, :no_contracts],
        # 如果 dialyzer 还是报错（比方说在新环境开发的时候）的话
        # 解除注释下面这行，在根目录创建对应的文件
        # ignore_warnings: "dialyzer.ignore"
        # 再输入
        # [{~c"./apps/hana_shirabe_weblib/hana_shirabe_web/gettext.ex", call_without_opaque}]
        #
        # 要是 ElixirLS 报错的话
        # 以 .vscode/settings.json 为例
        # {"elixirLS.dialyzerWarnOpts": ["no_opaque"]}
      ]
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
      {:phoenix_live_view, ">= 0.0.0"},
      # 不需要加上 gettext ，只需要在所用到的应用下面写入
      # 否则通不过编译
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
