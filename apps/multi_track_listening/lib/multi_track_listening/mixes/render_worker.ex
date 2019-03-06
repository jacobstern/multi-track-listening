defmodule MultiTrackListening.Mixes.RenderWorker do
  @behaviour Honeydew.Worker

  alias MultiTrackCruncher.Cruncher
  alias MultiTrackListening.Mixes
  alias MultiTrackListening.Mixes.{Render}
  alias MultiTrackListening.Storage
  alias MultiTrackWeb.{Endpoint, MixView}

  defp unique_temp_path() do
    uuid = UUID.uuid4()
    priv = :code.priv_dir(:multi_track_listening)
    Path.join(priv, "tmp/#{uuid}")
  end

  defp update_and_notify(render, updates) do
    updated = Mixes.update_render_internal(render, updates)
    payload = MixView.render("mix-render.json", mix_render: updated)
    Endpoint.broadcast!("mix_renders:#{updated.id}", "update", payload)
  end

  def do_render(render = %Render{}) do
    temp_directory = unique_temp_path()
    File.mkdir!(temp_directory)

    [track_one_path, track_two_path, destination_path] =
      Enum.map(
        ["track_one.mp3", "track_two.mp3", "output.mp3"],
        &Path.join(temp_directory, &1)
      )

    Storage.download_file!(render.track_one_file_uuid, track_one_path)
    Storage.download_file!(render.track_two_file_uuid, track_two_path)

    with :ok <-
           Cruncher.crunch_files(track_one_path, track_two_path, destination_path,
             start_l: render.track_one_start,
             start_r: render.track_two_start,
             mix_duration: render.mix_duration
           ) do
      result_file_uuid = Storage.upload_file!(destination_path, "audio/mpeg")
      update_and_notify(render, status: :finished, result_file_uuid: result_file_uuid)
    else
      _ ->
        update_and_notify(render, status: :error)
    end

    for path <- [track_one_path, track_two_path, destination_path] do
      File.rm!(path)
    end

    File.rmdir!(temp_directory)
  end
end
