defmodule MultiTrackListening.Repo.Migrations.MixRendersParams do
  use Ecto.Migration

  def change do
    alter table(:mix_renders) do
      add :track_one_file_uuid, :string
      add :track_two_file_uuid, :string
      add :mix_duration, :integer, null: false, default: 90
      add :track_one_start, :integer, null: false, default: 0
      add :track_two_start, :integer, null: false, default: 0
      add :drifting_speed, :float, null: false, default: 6.0
    end
  end
end
