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
      audio_file: "c05a05c6-80dd-4bc2-9ca1-4fd7ff7ce8c5",
      track_one_name: "Can't Feel My Face",
      track_two_name: "Regret"
    })

    Repo.insert!(%PublishedMix{
      audio_file: "8ec07f03-f3fb-42e8-93bf-108d9bb44fb1",
      track_one_name: "Gas Gas Gas",
      track_two_name: "Running In The 90s"
    })
  end

  def seed(:prod), do: nil
end
