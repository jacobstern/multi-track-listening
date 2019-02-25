defmodule MultiTrackListening.Repo.Migrations.MixRendersTrackName do
  use Ecto.Migration

  def change do
    alter table(:mix_renders) do
      add :track_one_name, :string
      add :track_two_name, :string
    end
  end
end
