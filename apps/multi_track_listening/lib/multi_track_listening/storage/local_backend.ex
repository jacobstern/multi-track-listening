defmodule MultiTrackListening.Storage.LocalBackend do
  defp generate_local_path(uuid) do
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "media", uuid])
  end

  def upload(uuid, file_path, _content_type), do: File.cp(file_path, generate_local_path(uuid))

  def remove(uuid), do: generate_local_path(uuid) |> File.rm()

  def serve_plug(uuid, content_type, conn) do
    result =
      conn
      |> Plug.Conn.put_resp_content_type(content_type)
      |> Plug.Conn.send_file(200, generate_local_path(uuid))

    {:ok, result}
  end

  def duplicate(uuid, uuid_dst) do
    File.cp(generate_local_path(uuid), generate_local_path(uuid_dst))
  end

  def download(uuid, file_path), do: File.cp(generate_local_path(uuid), file_path)
end
