use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :multi_track_listening, MultiTrackWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [host: "www.multitracklistening.net", scheme: "https"],
  check_origin: false,
  server: true,
  root: ".",
  cache_static_manifest: "priv/static/cache_manifest.json"

config :multi_track_listening, MultiTrackWeb.HomeController, featured_mix_ids: [2, 4, 1]

# Do not print debug messages in production
config :logger, level: :info

# ## Using releases (distillery)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :multi_track_listening, MultiTrackWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

config :multi_track_listening, MultiTrackListening.Storage.GoogleCloudBackend,
  bucket: "multi-track-listening-media-prod"

# Finally import the config/prod.secret.exs which should be versioned
# separately.
import_config "prod.secret.exs"
