defmodule MultiTrackListening.Mixes.RenderWorker do
  @behaviour Honeydew.Worker

  alias MultiTrackListening.Mixes
  alias MultiTrackListening.Storage

  defp unique_temp_path() do
    uuid = UUID.uuid4()
    priv = :code.priv_dir(:multi_track_listening)
    Path.join([priv, "tmp", uuid])
  end

  defp should_cancel(render) do
    render.status == :canceled || render.status == :aborted
  end

  def do_render(mix, render) do
    check_cancel = fn ->
      if not should_cancel(Mixes.get_mix_render!(mix.id, render.id)) do
        :ok
      end
    end

    {:ok, _} = Mixes.update_render_when_not_canceled(render, status: :in_progress)

    track_one_local_path = unique_temp_path()
    track_two_local_path = unique_temp_path()
    output_path = unique_temp_path()

    try do
      with :ok <- check_cancel.() do
        Storage.copy_file_locally!(mix.track_one.file_uuid, track_one_local_path)
        Storage.copy_file_locally!(mix.track_two.file_uuid, track_two_local_path)
      end
    after
      for path <- [track_one_local_path, track_two_local_path, output_path] do
        File.rm(path)
      end
    end
  end
end
