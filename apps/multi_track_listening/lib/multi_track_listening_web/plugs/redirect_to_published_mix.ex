defmodule MultiTrackListeningWeb.Plugs.RedirectToPublishedMix do
  alias MultiTrackListening.Mixes.Mix
  alias MultiTrackListeningWeb.Router.Helpers, as: Routes
  alias MultiTrackListening.PublishedMixes
  alias MultiTrackListening.PublishedMixes.PublishedMix

  def init(_), do: nil

  def call(conn = %Plug.Conn{assigns: %{mix: %Mix{published_mix_id: published_id}}}, _) do
    if not is_nil(published_id) do
      published = PublishedMixes.get_published_mix(published_id)

      redirect_to =
        Routes.published_mix_path(conn, :show, PublishedMix.author_slug(published), published)

      conn
      |> Phoenix.Controller.redirect(to: redirect_to)
      |> Plug.Conn.halt()
    else
      conn
    end
  end
end
