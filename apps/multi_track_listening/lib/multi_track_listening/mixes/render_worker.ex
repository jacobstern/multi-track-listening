defmodule MultiTrackListening.Mixes.RenderWorker do
  @behaviour Honeydew.Worker

  alias MultiTrackCruncher.Cruncher
  alias MultiTrackListening.Mixes
  alias MultiTrackListening.Mixes.{Mix}
  alias MultiTrackListening.Storage

  defp unique_temp_path() do
    uuid = UUID.uuid4()
    priv = :code.priv_dir(:multi_track_listening)
    Path.join(priv, "tmp/#{uuid}")
  end

  def do_render(
        mix_id,
        render_id,
        notify_update
      ) do
    update_and_notify = fn updates ->
      with result = {:ok, render} <- Mixes.update_render_when_not_canceled(render_id, updates) do
        notify_update.(render)
        result
      else
        result -> result
      end
    end

    %Mix{parameters: parameters, track_one: track_one, track_two: track_two} =
      Mixes.get_mix!(mix_id)

    with {:ok, _} <-
           update_and_notify.(
             status: :in_progress,
             track_one_name: track_one.name,
             track_two_name: track_two.name
           ) do
      temp_directory = unique_temp_path()
      File.mkdir!(temp_directory)

      [track_one_path, track_two_path, destination_path] =
        Enum.map(
          ["track_one.mp3", "track_two.mp3", "output.mp3"],
          &Path.join(temp_directory, &1)
        )

      try do
        Storage.download_file!(track_one.file_uuid, track_one_path)
        Storage.download_file!(track_two.file_uuid, track_two_path)

        :ok =
          Cruncher.crunch_files(track_one_path, track_two_path, destination_path,
            start_l: parameters.track_one_start,
            start_r: parameters.track_two_start,
            mix_duration: parameters.mix_duration
          )

        file_uuid = Storage.upload_file!(destination_path, "audio/mpeg")

        update_and_notify.(
          status: :finished,
          result_file_uuid: file_uuid
        )
      rescue
        e ->
          update_and_notify.(status: :error)
          raise e
      after
        for path <- [track_one_path, track_two_path, destination_path] do
          File.rm(path)
        end

        File.rmdir(temp_directory)
      end
    end
  end
end
