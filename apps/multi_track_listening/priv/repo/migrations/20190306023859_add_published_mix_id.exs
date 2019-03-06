defmodule MultiTrackListening.Repo.Migrations.AddPublishedMixId do
  use Ecto.Migration

  def change do
    alter table(:mixes) do
      add :published_mix_id, references(:published_mixes)
    end
  end
end
