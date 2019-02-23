defmodule MultiTrackListening.Repo.Migrations.CreateMixRenders do
  use Ecto.Migration

  def change do
    create table(:mix_renders) do
      add :status, :integer, null: false
      add :result_file_uuid, :string
      add :mix_id, references(:mixes, on_delete: :nilify_all)

      timestamps()
    end

    create index(:mix_renders, [:mix_id])
  end
end
