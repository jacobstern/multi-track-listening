defmodule MultiTrackListening.Mixes.TrackUpload do
  use Ecto.Schema
  import Ecto.Changeset
  import MultiTrackListening.Ecto.Changeset

  @supported_content_types ["audio/mpeg"]

  embedded_schema do
    field(:name, :string)
    field(:client_uuid, :string)
    field(:file, :any, virtual: true)
  end

  @doc false
  def changeset(track_upload, attrs) do
    track_upload
    |> cast(attrs, [:name, :client_uuid, :file])
    |> validate_required([:name, :file])
    |> validate_length(:name, min: 3)
    |> validate_content_type_inclusion(:file, @supported_content_types)
  end
end
