defmodule MultiTrackListening.Storage do
  @moduledoc """
  The Storage context.
  """

  defmodule FileId do
    @type t() :: String.t()
  end

  defmodule InvalidFileId do
    defexception [:message]
  end

  defmodule BackendError do
    defexception [:message, :operation, :reason]
  end

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage

  defp unwrap_backend_result(:ok, _func), do: :ok

  defp unwrap_backend_result({:ok, result}, _func), do: result

  defp unwrap_backend_result({:error, reason}, func) do
    raise %BackendError{
      operation: func,
      reason: reason,
      message: "backend module returned failure"
    }
  end

  defp get_backend() do
    Application.get_env(:multi_track_listening, MultiTrackListening.Storage)
    |> Keyword.get(:backend)
  end

  defp backend_call(func, args) do
    get_backend()
    |> apply(func, args)
    |> unwrap_backend_result(func)
  end

  defp gen_uuid(), do: UUID.uuid4()

  defp create_file_record(uuid, content_type) do
    backend = get_backend().backend_identifier()
    Repo.insert!(%Storage.File{backend: backend, content_type: content_type, uuid: uuid})
  end

  @spec upload_file!(Path.t(), String.t()) :: FileId.t()
  def upload_file!(file_path, content_type) do
    uuid = gen_uuid()
    backend_call(:upload, [uuid, file_path, content_type])
    create_file_record(uuid, content_type)
    uuid
  end

  defp get_file_record!(uuid) do
    case Repo.get_by(Storage.File, uuid: uuid) do
      file = %Storage.File{} -> file
      _ -> raise %InvalidFileId{message: "invalid file id #{uuid}"}
    end
  end

  @spec delete_file!(FileId.t()) :: :ok
  def delete_file!(uuid) do
    backend_call(:remove, [uuid])
    uuid |> get_file_record!() |> Repo.delete!()
  end

  @spec get_file_content_type!(FileId.t()) :: String.t()
  def get_file_content_type!(uuid) do
    %Storage.File{content_type: content_type} = get_file_record!(uuid)
    content_type
  end

  @spec file_url(FileId.t()) :: String.t()
  def file_url(uuid) do
    backend_call(:url, [uuid])
  end

  @spec download_file!(FileId.t(), Path.t()) :: :ok
  def download_file!(uuid, file_path) do
    backend_call(:download, [uuid, file_path])
  end

  @spec duplicate_file!(FileId.t()) :: FileId.t()
  def duplicate_file!(uuid) do
    uuid_dst = gen_uuid()
    backend_call(:duplicate, [uuid, uuid_dst])
    file = get_file_record!(uuid)
    create_file_record(uuid_dst, file.content_type)
    uuid_dst
  end
end
