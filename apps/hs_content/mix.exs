defmodule HSContent.MixProject do
  use Mix.Project

  def project do
    [
      app: :hs_content,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mdex, "~> 0.10"}
      # 为啥不用 Earmark ？因为那个库和 HTML 耦合太高了。
      # 最好还是一个 agnostic-AST ，可以渲染成 Markdown 以及 HTML 的。
    ]
  end
end
