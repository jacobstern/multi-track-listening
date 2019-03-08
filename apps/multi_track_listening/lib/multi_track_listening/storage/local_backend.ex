defmodule MultiTrackListening.Storage.LocalBackend do
  def backend_identifier(), do: "local"

  def generate_local_path(uuid) do
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "media", uuid])
  end

  def upload(uuid, file_path, _content_type, _options) do
    File.cp(file_path, generate_local_path(uuid))
  end

  def remove(uuid), do: generate_local_path(uuid) |> File.rm()

  def duplicate(uuid, uuid_dst) do
    File.cp(generate_local_path(uuid), generate_local_path(uuid_dst))
  end

  def download(uuid, file_path), do: File.cp(generate_local_path(uuid), file_path)

  def url(uuid), do: {:ok, "/uploads/#{uuid}"}
end
