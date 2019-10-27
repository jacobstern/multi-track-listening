defmodule MultiTrackListening.Mixes.RenderWorker do
  @behaviour Honeydew.Worker

  alias MultiTrackCruncher.Cruncher
  alias MultiTrackListening.Mixes
  alias MultiTrackListening.Mixes.{Render}
  alias MultiTrackListening.Storage
  alias MultiTrackWeb.{Endpoint, MixView}

  defmodule CruncherError do
    defexception [:message]
  end

  defp unique_temp_path() do
    uuid = UUID.uuid4()
    priv = :code.priv_dir(:multi_track_listening)
    Path.join(priv, "tmp/#{uuid}")
  end

  defp update_and_notify(render, updates) do
    updated = Mixes.update_render_internal(render, updates)

    Endpoint.broadcast!(
      "mix_renders:#{updated.id}",
      "update",
      MixView.render("mix-render.json", mix_render: updated)
    )
  end

  def do_render(render = %Render{}) do
    temp_directory = unique_temp_path()
    File.mkdir!(temp_directory)

    [track_one_path, track_two_path, destination_path] =
      Enum.map(
        ["track_one.mp3", "track_two.mp3", "output.mp3"],
        &Path.join(temp_directory, &1)
      )

    try do
      Storage.download_file!(render.track_one_file_uuid, track_one_path)
      Storage.download_file!(render.track_two_file_uuid, track_two_path)

      case Cruncher.crunch_files(track_one_path, track_two_path, destination_path,
             start_l: render.track_one_start,
             start_r: render.track_two_start,
             drifting_speed: render.drifting_speed,
             mix_duration: render.mix_duration,
             gain_l: render.track_one_gain,
             gain_r: render.track_two_gain
           ) do
        :ok ->
          filename = "#{render.track_one_name} x #{render.track_two_name}.mp3"

          result_file_uuid =
            Storage.upload_file!(destination_path, "audio/mpeg", filename: filename)

          update_and_notify(render, status: :finished, result_file_uuid: result_file_uuid)

        error ->
          raise %CruncherError{message: "error from cruncher: #{inspect(error)}"}
      end
    rescue
      error ->
        update_and_notify(render, status: :error)
        raise error
    after
      for path <- [track_one_path, track_two_path, destination_path], File.exists?(path) do
        File.rm!(path)
      end

      File.rmdir!(temp_directory)
    end
  end
end
