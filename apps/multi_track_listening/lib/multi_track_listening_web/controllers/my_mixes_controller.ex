defmodule MultiTrackListeningWeb.MyMixesController do
  use MultiTrackListeningWeb, :controller
  alias MultiTrackListening.{PublishedMixes, Storage}

  def show(conn, _params) do
    user = Pow.Plug.current_user(conn)

    mix_items =
      for mix <- PublishedMixes.published_mixes_for_author(user) do
        %{
          mix: mix,
          audio_url: Storage.file_url(mix.audio_file)
        }
      end

    render(conn, "show.html", mixes: mix_items)
  end
end
