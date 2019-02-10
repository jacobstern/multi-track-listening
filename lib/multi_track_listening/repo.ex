defmodule MultiTrackListening.Repo do
  use Ecto.Repo,
    otp_app: :multi_track_listening,
    adapter: Ecto.Adapters.Postgres
end
