defmodule MultiTrackListeningWeb.HomeController do
  use MultiTrackListeningWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end