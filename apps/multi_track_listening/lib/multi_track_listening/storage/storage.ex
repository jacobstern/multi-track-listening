defmodule MultiTrackListening.Storage do
  @moduledoc """
  The Storage context.
  """

  @type uuid_t() :: String.t()

  defmodule InvalidFileError do
    defexception [:message]
  end

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage
  alias Plug.Conn

  defp generate_local_path(uuid) do
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "media", uuid])
  end

  defp create_file_record(content_type) do
    uuid = UUID.uuid4()
    Repo.insert!(%Storage.File{backend: "local", content_type: content_type, uuid: uuid})
  end

  @spec persist_file(File.Path.t(), uuid_t()) :: uuid_t()
  def persist_file(file_path, content_type) do
    %Storage.File{uuid: uuid} = create_file_record(content_type)
    File.cp!(file_path, generate_local_path(uuid))
    uuid
  end

  defp get_file(uuid) do
    case Repo.get_by(Storage.File, uuid: uuid) do
      file = %Storage.File{} -> file
      _ -> raise %InvalidFileError{message: "invalid file uuid #{uuid}"}
    end
  end

  @spec delete_file(uuid_t()) :: :ok
  def delete_file(uuid) do
    get_file(uuid) |> Repo.delete!()
    File.rm!(generate_local_path(uuid))
  end

  @spec serve_file!(uuid_t(), Plug.Conn.t()) :: Plug.Conn.t()
  def serve_file!(uuid, conn) do
    %Storage.File{content_type: content_type} = get_file(uuid)

    conn
    |> Conn.put_resp_content_type(content_type)
    |> Conn.send_file(200, generate_local_path(uuid))
  end

  @spec copy_file_locally!(uuid_t(), File.Path.t()) :: :ok
  def copy_file_locally!(uuid, destination_path) do
    File.cp!(generate_local_path(uuid), destination_path)
  end

  def duplicate_file!(uuid) do
    file = get_file(uuid)
    %Storage.File{uuid: new_uuid} = create_file_record(file.content_type)
    File.cp!(generate_local_path(uuid), generate_local_path(new_uuid))
    new_uuid
  end
end
