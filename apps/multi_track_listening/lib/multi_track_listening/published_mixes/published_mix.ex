defmodule MultiTrackListening.PublishedMixes.PublishedMix do
  use Ecto.Schema
  import Ecto.Changeset
  alias MultiTrackListening.Storage
  alias MultiTrackListening.Mixes.{Mix, Render}

  @type t :: %__MODULE__{
          id: integer,
          audio_file: Storage.FileId.t(),
          track_one_name: String.t(),
          track_two_name: String.t(),
          mix: Mix.t() | Ecto.Association.NotLoaded.t(),
          render: Render.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "published_mixes" do
    field :audio_file, :string
    field :track_one_name, :string
    field :track_two_name, :string

    has_one :mix, Mix
    has_one :render, Render

    timestamps()
  end

  @doc false
  def changeset(published_mix, attrs) do
    published_mix
    |> cast(attrs, [:track_one_name, :track_two_name])
    |> validate_required([:track_one_name, :track_two_name])
  end
end
