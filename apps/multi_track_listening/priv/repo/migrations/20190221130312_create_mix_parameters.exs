defmodule MultiTrackListening.Repo.Migrations.CreateMixParameters do
  use Ecto.Migration

  def change do
    create table(:mix_parameters) do
      add :track_one_start, :integer, null: false
      add :track_two_start, :integer, null: false
      add :mix_duration, :integer, null: false

      add :mix_id, references(:mixes, on_delete: :delete_all)

      timestamps()
    end
  end
end
