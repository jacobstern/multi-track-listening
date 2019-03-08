defmodule MultiTrackListening.Repo.Migrations.AddRenderPublishedMixId do
  use Ecto.Migration

  def change do
    alter table(:mix_renders) do
      add :published_mix_id, references(:published_mixes)
    end
  end
end
