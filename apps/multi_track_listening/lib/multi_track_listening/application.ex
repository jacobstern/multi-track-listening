defmodule MultiTrackListening.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      MultiTrackListening.Repo,
      # Start the endpoint when the application starts
      MultiTrackWeb.Endpoint
      # Starts a worker by calling: MultiTrackListening.Worker.start_link(arg)
      # {MultiTrackListening.Worker, arg},
    ]

    :ok = Honeydew.start_queue(:mix_render_queue)
    :ok = Honeydew.start_workers(:mix_render_queue, MultiTrackListening.Mixes.RenderWorker)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MultiTrackListening.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MultiTrackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
