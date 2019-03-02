defmodule MultiTrackWeb.HomeController do
  use MultiTrackWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
