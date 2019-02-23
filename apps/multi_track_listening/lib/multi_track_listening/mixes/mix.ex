defmodule MultiTrackListening.Mixes.Mix do
  use Ecto.Schema
  import Ecto.Changeset
  alias MultiTrackListening.Mixes.{Track, MixParameters}

  schema "mixes" do
    embeds_one :track_one, Track, on_replace: :delete
    embeds_one :track_two, Track, on_replace: :delete

    has_one :parameters, MixParameters

    timestamps()
  end

  @doc false
  def changeset(mix, attrs) do
    mix
    |> cast(attrs, [])
    |> cast_assoc(:parameters, with: &MixParameters.changeset/2)
    |> cast_embed(:track_one, with: &Track.changeset/2)
    |> cast_embed(:track_two, with: &Track.changeset/2)
  end
end
