defmodule MultiTrackListening.Repo.Migrations.CreateMixes do
  use Ecto.Migration

  def change do
    create table(:mixes) do
      add :track_one, :map
      add :track_two, :map

      timestamps()
    end

  end
end
