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

  def do_render(mix = %Mix{parameters: parameters}, render) do
    with {:ok, _} <- Mixes.update_render_when_not_canceled(render, status: :in_progress) do
      temp_directory = unique_temp_path()
      File.mkdir!(temp_directory)

      [track_one_path, track_two_path, destination_path] =
        Enum.map(
          ["track_one.mp3", "track_two.mp3", "output.mp3"],
          &Path.join(temp_directory, &1)
        )

      try do
        Storage.copy_file_locally!(mix.track_one.file_uuid, track_one_path)
        Storage.copy_file_locally!(mix.track_two.file_uuid, track_two_path)

        Cruncher.crunch_files(track_one_path, track_two_path, destination_path,
          mix_duration: parameters.mix_duration,
          start_l: parameters.track_one_start,
          start_r: parameters.track_two_start
        )

        file_uuid = Storage.persist_file(destination_path, "audio/mpeg")

        Mixes.update_render_when_not_canceled(render,
          status: :finished,
          result_file_uuid: file_uuid
        )
      rescue
        e ->
          Mixes.update_render_when_not_canceled(render, status: :error)
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
