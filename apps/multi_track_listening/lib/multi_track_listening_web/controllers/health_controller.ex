defmodule MultiTrackListeningWeb.HealthController do
  use MultiTrackListeningWeb, :controller
  import Plug.Conn

  def index(conn, _) do
    conn |> send_resp(200, "OK")
  end
end
