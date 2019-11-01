defmodule MultiTrackListeningWeb.StorageController do
  use MultiTrackListeningWeb, :controller

  alias MultiTrackListening.Storage
  alias MultiTrackListening.Storage.LocalBackend

  def serve_file(conn, %{"uuid" => uuid}) do
    content_type = Storage.get_file_content_type!(uuid)

    conn
    |> Plug.Conn.put_resp_content_type(content_type)
    |> Plug.Conn.send_file(200, LocalBackend.generate_local_path(uuid))
  end
end
