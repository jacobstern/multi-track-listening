defmodule MultiTrackListening.Repo.Migrations.CreateListens do
  use Ecto.Migration

  def change do
    create table(:listens) do
      add :track_one_name, :string
      add :track_two_name, :string
      add :audio_file_uuid, :string, null: false

      timestamps()
    end
  end
end
