defmodule MultiTrackListening.Storage.GoogleCloudBackend do
  def backend_identifier(), do: "gcs"

  defp get_conn() do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    GoogleApi.Storage.V1.Connection.new(token.token)
  end

  defp bucket_from_config() do
    Application.get_env(:multi_track_listening, MultiTrackListening.Storage.GoogleCloudBackend)
    |> Keyword.get(:bucket)
  end

  defp generate_object_url(uuid) do
    bucket = bucket_from_config()
    "https://#{bucket}.storage.googleapis.com/#{uuid}"
  end

  def upload(uuid, file_path, content_type) do
    # Added this check as the Google client library function does not seem to handle missing file well
    if File.exists?(file_path) do
      with {:ok, _object} <-
             GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
               get_conn(),
               bucket_from_config(),
               "multipart",
               %GoogleApi.Storage.V1.Model.Object{
                 name: uuid,
                 contentType: content_type,
                 contentDisposition: "attachment"
               },
               file_path
             ) do
        :ok
      end
    else
      {:error, :file_missing}
    end
  end

  def remove(uuid) do
    with {:ok, nil} <-
           GoogleApi.Storage.V1.Api.Objects.storage_objects_delete(
             get_conn(),
             bucket_from_config(),
             uuid
           ) do
      :ok
    end
  end

  def serve_plug(uuid, _content_type, conn) do
    result =
      conn
      |> Plug.Conn.put_resp_header("location", generate_object_url(uuid))
      |> Plug.Conn.resp(301, "You are being redirected.")
      |> Plug.Conn.halt()

    {:ok, result}
  end

  def url(uuid), do: {:ok, generate_object_url(uuid)}

  def duplicate(uuid, uuid_dst) do
    bucket = bucket_from_config()

    with {:ok, _object} <-
           GoogleApi.Storage.V1.Api.Objects.storage_objects_copy(
             get_conn(),
             bucket,
             uuid,
             bucket,
             uuid_dst
           ) do
      :ok
    end
  end

  def download(uuid, file_path) do
    with {:ok, response} <- HTTPoison.get(generate_object_url(uuid)) do
      File.write(file_path, response.body)
    end
  end
end
