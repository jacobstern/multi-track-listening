defmodule MultiTrackListening.Storage do
  @moduledoc """
  The Storage context.
  """

  defmodule InvalidFileError do
    defexception [:message]
  end

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage

  defp generate_local_path(uuid) do
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "media", uuid])
  end

  @spec persist_file(File.Path.t(), String.t()) :: String.t()
  def persist_file(file_path, content_type) do
    uuid = UUID.uuid4()
    File.cp!(file_path, generate_local_path(uuid))
    Repo.insert!(%Storage.File{backend: "local", content_type: content_type, uuid: uuid})
    uuid
  end

  defp get_file(uuid) do
    case Repo.get_by(Storage.File, uuid: uuid) do
      file = %Storage.File{} -> file
      _ -> raise %InvalidFileError{message: "invalid file uuid #{uuid}"}
    end
  end

  @spec delete_file(String.t()) :: :ok
  def delete_file(uuid) do
    get_file(uuid) |> Repo.delete!()
    File.rm!(generate_local_path(uuid))
  end

  @spec file_url(String.t()) :: String.t()
  def file_url(uuid) do
    "/uploads/#{uuid}"
  end

  @spec copy_file_locally!(String.t(), File.Path.t()) :: :ok
  def copy_file_locally!(uuid, destination_path) do
    File.cp!(generate_local_path(uuid), destination_path)
  end
end
