defmodule MultiTrackWeb.Plugs.RedirectToPublishedMix do
  alias MultiTrackListening.Mixes.Mix
  alias MultiTrackWeb.Router.Helpers, as: Routes

  def init(_), do: nil

  def call(conn = %Plug.Conn{assigns: %{mix: %Mix{published_mix_id: published_id}}}, _) do
    if not is_nil(published_id) do
      redirect_to = Routes.published_mix_path(conn, :show, published_id)

      conn
      |> Phoenix.Controller.redirect(to: redirect_to)
      |> Plug.Conn.halt()
    else
      conn
    end
  end
end
