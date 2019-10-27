defmodule MultiTrackCruncher.Cruncher do
  # Line 22 producers a Dialyzer error, not sure why
  @dialyzer [{:nowarn_function, crunch_files: 3}, {:nowarn_function, crunch_files: 4}]

  defp extra_args_from_keyword_list(opts) do
    opts
    |> Enum.map(fn
      {:start_l, start} -> ["--start-l", Integer.to_string(start)]
      {:start_r, start} -> ["--start-r", Integer.to_string(start)]
      {:mix_duration, duration} -> ["--mix-duration", Integer.to_string(duration)]
      {:drifting_speed, drifting_speed} -> ["--drifting-speed", Float.to_string(drifting_speed)]
      {:gain_l, gain} -> ["--gain-l", Float.to_string(gain)]
      {:gain_r, gain} -> ["--gain-r", Float.to_string(gain)]
      _ -> []
    end)
    |> List.flatten()
  end

  @spec crunch_files(Path.t(), Path.t(), Path.t(), keyword()) :: :ok | {:error, :exit}
  def crunch_files(track_one_path, track_two_path, destination_path, opts \\ []) do
    cruncher_path = Path.join([:code.priv_dir(:multi_track_cruncher), "c", "cruncher"])
    cruncher_base_args = [track_one_path, track_two_path, "-o", destination_path]
    cruncher_args = cruncher_base_args ++ extra_args_from_keyword_list(opts)

    port = Port.open({:spawn_executable, cruncher_path}, [:exit_status, args: cruncher_args])
    Process.link(port)

    receive do
      {^port, {:exit_status, 0}} -> :ok
      {^port, {:exit_status, _}} -> {:error, :exit}
    end
  end
end
