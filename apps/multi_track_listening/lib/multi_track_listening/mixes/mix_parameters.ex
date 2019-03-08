defmodule MultiTrackListening.Mixes.MixParameters do
  use Ecto.Schema
  import Ecto.Changeset

  alias MultiTrackListening.Mixes.Mix

  @type t :: %__MODULE__{
          id: integer,
          mix_duration: integer,
          track_one_start: integer,
          track_two_start: integer,
          mix_id: integer,
          mix: Mix.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "mix_parameters" do
    field :mix_duration, :integer, default: 60
    field :track_one_start, :integer, default: 0
    field :track_two_start, :integer, default: 0

    belongs_to :mix, Mix

    timestamps()
  end

  @doc false
  def changeset(mix_parameters, attrs) do
    mix_parameters
    |> cast(attrs, [:track_one_start, :track_two_start, :mix_duration])
    |> validate_number(:track_one_start, greater_than_or_equal_to: 0)
    |> validate_number(:track_two_start, greater_than_or_equal_to: 0)
    |> validate_number(:mix_duration, greater_than_or_equal_to: 5)
    |> validate_number(:mix_duration, less_than_or_equal_to: 90)
    |> validate_required([:track_one_start, :track_two_start, :mix_duration])
  end
end
