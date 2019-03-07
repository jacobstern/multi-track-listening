defmodule MultiTrackListening.Repo.Migrations.MixRendersParams do
  use Ecto.Migration

  def change do
    alter table(:mix_renders) do
      add :track_one_file_uuid, :string
      add :track_two_file_uuid, :string
      add :mix_duration, :integer
      add :track_one_start, :integer
      add :track_two_start, :integer
      add :drifting_speed, :float
    end
  end
end
