defmodule MultiTrackListeningWeb.PublishedMixController do
  use MultiTrackListeningWeb, :controller

  alias MultiTrackListening.{PublishedMixes, Storage}
  alias MultiTrackListening.PublishedMixes.PublishedMix

  def show(conn, %{"id" => id, "author_slug" => author_slug}) do
    published = PublishedMixes.get_published_mix!(id)
    expected_slug = PublishedMix.author_slug(published)

    if author_slug == expected_slug do
      audio_url = Storage.file_url(published.audio_file)
      render(conn, "show.html", mix: published, audio_url: audio_url)
    else
      redirect_to = Routes.published_mix_path(conn, :show, expected_slug, published)

      conn
      |> Phoenix.Controller.redirect(to: redirect_to)
      |> Plug.Conn.halt()
    end
  end
end
