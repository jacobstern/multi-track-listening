defmodule MultiTrackListening.Storage do
  @moduledoc """
  The Storage context.
  """

  defmodule InvalidUuidError do
    defexception [:message]
  end

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage

  defp generate_local_path(uuid) do
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "media", uuid])
  end

  def persist_file(local_file, content_type) do
    uuid = UUID.uuid4()
    File.cp!(local_file, generate_local_path(uuid))
    Repo.insert!(%Storage.File{backend: "local", content_type: content_type, uuid: uuid})
  end

  @spec get_file_by_uuid(String.t()) :: Storage.File.t()
  def get_file_by_uuid(uuid) do
    case Repo.get_by(Storage.File, uuid: uuid) do
      file = %Storage.File{} -> file
      _ -> raise %InvalidUuidError{message: "invalid file uuid #{uuid}"}
    end
  end

  @spec delete_file_by_uuid(String.t()) :: :ok
  def delete_file_by_uuid(uuid) do
    get_file_by_uuid(uuid) |> Repo.delete!()
    File.rm!(generate_local_path(uuid))
  end
end
