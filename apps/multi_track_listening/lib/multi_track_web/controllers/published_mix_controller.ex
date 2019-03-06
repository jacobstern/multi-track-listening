defmodule MultiTrackWeb.PublishedMixController do
  use MultiTrackWeb, :controller

  def published_mix(conn, %{"id" => id}) do
    render(conn, "published-mix.html")
  end
end
