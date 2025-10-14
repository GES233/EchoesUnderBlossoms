defmodule HanaShirabeWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HanaShirabeWeb.Telemetry,
      # Start a worker by calling: HanaShirabeWeb.Worker.start_link(arg)
      # {HanaShirabeWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      HanaShirabeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HanaShirabeWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HanaShirabeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
