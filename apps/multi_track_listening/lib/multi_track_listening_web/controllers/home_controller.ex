defmodule MultiTrackListeningWeb.HomeController do
  use MultiTrackListeningWeb, :controller
  alias MultiTrackListening.{PublishedMixes, Storage}

  defp get_featured_mixes() do
    featured_mix_ids =
      Application.get_env(:multi_track_listening, MultiTrackListeningWeb.HomeController, [])
      |> Keyword.get(:featured_mix_ids, [])

    for id <- featured_mix_ids,
        mix = PublishedMixes.get_published_mix(id),
        not is_nil(mix) do
      mix
    end
  end

  def index(conn, _params) do
    render(conn, "index.html",
      featured_mixes:
        for mix <- get_featured_mixes() do
          %{
            mix: mix,
            audio_url: Storage.file_url(mix.audio_file)
          }
        end
    )
  end
end
