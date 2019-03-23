defmodule MultiTrackListening.Repo.Migrations.AddDriftingSpeed do
  use Ecto.Migration

  def change do
    alter table(:mix_parameters) do
      add :drifting_speed, :float, null: false, default: 6.0
    end
  end
end
