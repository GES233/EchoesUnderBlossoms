defmodule HanaShirabe.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HanaShirabe.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:hana_shirabe, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:hana_shirabe, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HanaShirabe.PubSub}
      # {HanaShirabe.Worker, arg} 其实是 HanaShirabe.Worker.start_link(arg)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: HanaShirabe.Supervisor)
  end

  defp skip_migrations?() do
    # 默认情况下，使用发布版本时运行 SQLite 迁移
    System.get_env("RELEASE_NAME") == nil
  end
end
