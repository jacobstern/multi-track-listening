defmodule MultiTrackListening.Mixes.Render do
  use Ecto.Schema
  import EctoEnum

  alias MultiTrackListening.Mixes.Mix
  alias MultiTrackListening.PublishedMixes.PublishedMix

  defenum(StatusEnum, requested: 0, in_progress: 1, finished: 2, error: 3, canceled: 4, aborted: 5)

  @type t :: %__MODULE__{
          id: integer,
          track_one_file_uuid: String.t(),
          track_two_file_uuid: String.t(),
          result_file_uuid: String.t(),
          mix_duration: integer,
          track_one_start: integer,
          track_two_start: integer,
          track_one_gain: float,
          track_two_gain: float,
          drifting_speed: float,
          track_one_name: String.t(),
          track_two_name: String.t(),
          status: :requested | :in_progress | :finished | :error | :canceled | :aborted,
          mix_id: integer,
          mix: Mix.t(),
          published_mix: PublishedMix.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  def is_canceled(render) do
    render.status == :canceled || render.status == :aborted
  end

  schema "mix_renders" do
    field :track_one_file_uuid, :string
    field :track_two_file_uuid, :string
    field :result_file_uuid, :string

    field :mix_duration, :integer
    field :track_one_start, :integer
    field :track_two_start, :integer
    field :drifting_speed, :float

    field :track_one_gain, :float
    field :track_two_gain, :float

    field :track_one_name, :string
    field :track_two_name, :string

    field :status, StatusEnum, default: :requested

    belongs_to :mix, Mix
    belongs_to :published_mix, PublishedMix

    timestamps()
  end
end
