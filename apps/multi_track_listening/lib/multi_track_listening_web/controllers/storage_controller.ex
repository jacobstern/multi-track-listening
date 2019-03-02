defmodule MultiTrackWeb.StorageController do
  use MultiTrackWeb, :controller

  alias MultiTrackListening.Storage

  def serve_file(conn, %{"uuid" => uuid}) do
    Storage.serve_file!(uuid, conn)
  end
end
