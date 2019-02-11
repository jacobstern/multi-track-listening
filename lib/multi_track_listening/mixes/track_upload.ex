defmodule MultiTrackListening.Mixes.TrackUpload do
  use Ecto.Schema
  import Ecto.Changeset
  import MultiTrackListening.Ecto.Changeset

  @supported_content_types ["audio/mpeg"]
  @unsupported_content_type_message "must be an mp3 file"

  embedded_schema do
    field :name, :string
    field :file, :any, virtual: true
  end

  @doc false
  def changeset(track_upload, attrs) do
    track_upload
    |> cast(attrs, [:name, :file])
    |> validate_required([:name, :file])
    |> validate_length(:name, min: 3)
    |> validate_content_type_inclusion(:file, @supported_content_types,
      message: @unsupported_content_type_message
    )
  end
end
