defmodule MultiTrackWeb.PublishedMixController do
  use MultiTrackWeb, :controller

  alias MultiTrackListening.{PublishedMixes, Storage}

  def show(conn, %{"id" => id}) do
    published_mix = %{audio_file: audio_file} = PublishedMixes.get_published_mix!(id)
    audio_url = Storage.file_url(audio_file)
    render(conn, "show.html", published_mix: published_mix, audio_url: audio_url)
  end
end
