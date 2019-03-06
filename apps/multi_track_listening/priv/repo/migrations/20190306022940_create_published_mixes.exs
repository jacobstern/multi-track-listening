defmodule MultiTrackListening.Repo.Migrations.CreatePublishedMixes do
  use Ecto.Migration

  def change do
    create table(:published_mixes) do
      add :audio_file, :string, null: false
      add :track_one_name, :string, null: false
      add :track_two_name, :string, null: false

      timestamps()
    end
  end
end
