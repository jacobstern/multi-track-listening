defmodule MultiTrackListening.Repo.Migrations.AddMixAuthor do
  use Ecto.Migration

  def change do
    alter table(:published_mixes) do
      add :author_id, references(:users)
    end
  end
end
