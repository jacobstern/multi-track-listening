defmodule MultiTrackListening.Storage.File do
  use Ecto.Schema


  schema "storage_files" do
    field :backend, :string, null: false
    field :content_type, :string, null: false
    field :uuid, :string, null: false

    timestamps()
  end
end
