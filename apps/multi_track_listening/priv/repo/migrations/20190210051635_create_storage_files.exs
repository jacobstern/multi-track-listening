defmodule MultiTrackListening.Repo.Migrations.CreateStorageFiles do
  use Ecto.Migration

  def change do
    create table(:storage_files) do
      add :uuid, :string, null: false
      add :content_type, :string, null: false
      add :backend, :string, null: false

      timestamps()
    end

    create unique_index(:storage_files, [:uuid])
  end
end
