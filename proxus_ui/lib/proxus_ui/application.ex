defmodule ProxusUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ProxusUiWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ProxusUi.PubSub},
      # Start the Endpoint (http/https)
      ProxusUiWeb.Endpoint
      # Start a worker by calling: ProxusUi.Worker.start_link(arg)
      # {ProxusUi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ProxusUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ProxusUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end