defmodule Mix.Tasks.MultiTrackListening.Seed do
  use Mix.Task
  alias MultiTrackListening.Repo
  alias MultiTrackListening.PublishedMixes.PublishedMix

  def run(_) do
    Mix.Task.run("app.start", [])
    seed(Mix.env())
  end

  def seed(:dev) do
    Repo.insert!(%PublishedMix{
      audio_file: "159099e1-e5d8-4e6a-809e-7c0226f944dd",
      track_one_name: "Can't Feel My Face",
      track_two_name: "Regret"
    })
  end

  def seed(:prod), do: nil
end
