defmodule MultiTrackListening.Repo.Migrations.GainParameter do
  use Ecto.Migration

  def change do
    alter table(:mix_renders) do
      add :track_one_gain, :float, default: 1.0
      add :track_two_gain, :float, default: 1.0
    end

    alter table(:mix_parameters) do
      add :track_one_gain, :float, default: 1.0
      add :track_two_gain, :float, default: 1.0
    end
  end
end
