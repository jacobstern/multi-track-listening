defmodule MultiTrackListening.Mixes.Mix do
  use Ecto.Schema
  import Ecto.Changeset
  alias MultiTrackListening.Mixes.{Track, MixParameters}
  alias MultiTrackListening.PublishedMixes.PublishedMix

  @type t :: %__MODULE__{
          id: integer,
          track_one: Track.t(),
          track_two: Track.t(),
          parameters: MixParameters.t(),
          published_mix_id: integer,
          published_mix: PublishedMix.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "mixes" do
    embeds_one :track_one, Track, on_replace: :delete
    embeds_one :track_two, Track, on_replace: :delete

    has_one :parameters, MixParameters, on_replace: :update

    belongs_to :published_mix, PublishedMix

    timestamps()
  end

  @spec is_published(t()) :: boolean()
  def is_published(mix = %__MODULE__{}), do: not is_nil(mix.published_mix_id)

  @doc false
  def changeset(mix, attrs) do
    mix
    |> cast(attrs, [])
    |> cast_assoc(:parameters, with: &MixParameters.changeset/2)
    |> cast_embed(:track_one, with: &Track.changeset/2)
    |> cast_embed(:track_two, with: &Track.changeset/2)
  end
end
