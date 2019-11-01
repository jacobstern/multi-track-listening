# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :multi_track_listening,
  ecto_repos: [MultiTrackListening.Repo]

# Configures the endpoint
config :multi_track_listening, MultiTrackListeningWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "h81nMgXq9ucOOBIKmnTB6vppIC9kXu+oBOBVI8fZ+NJl0ByeTsBHB5ltCaoJm53r",
  render_errors: [view: MultiTrackListeningWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MultiTrackListening.PubSub, adapter: Phoenix.PubSub.PG2]

config :multi_track_listening, :pow,
  user: MultiTrackListening.Users.User,
  repo: MultiTrackListening.Repo,
  web_module: MultiTrackListeningWeb,
  extensions: [PowResetPassword, PowEmailConfirmation],
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  mailer_backend: MultiTrackListeningWeb.PowMailer

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Enable Markdown templates
config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

config :multi_track_listening, MultiTrackListening.Storage,
  backend: MultiTrackListening.Storage.GoogleCloudBackend

config :goth, project_id: "multi-track-listening"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
