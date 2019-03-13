defmodule MultiTrackWeb.HealthController do
  use MultiTrackWeb, :controller
  import Plug.Conn

  def index(conn, _) do
    conn |> send_resp(200, "OK")
  end
end
