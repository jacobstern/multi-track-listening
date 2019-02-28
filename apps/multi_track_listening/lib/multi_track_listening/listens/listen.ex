defmodule MultiTrackListening.Listens.Listen do
  use Ecto.Schema
  import Ecto.Changeset


  schema "listens" do
    field :audio_file_uuid, :string
    field :track_one_name, :string
    field :track_two_name, :string

    timestamps()
  end

  @doc false
  def changeset(listen, attrs) do
    listen
    |> cast(attrs, [:track_one_name, :track_two_name, :audio_file_uuid])
    |> validate_required([:track_one_name, :track_two_name, :audio_file_uuid])
  end
end
