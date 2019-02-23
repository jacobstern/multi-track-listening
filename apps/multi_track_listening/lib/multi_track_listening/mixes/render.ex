defmodule MultiTrackListening.Mixes.Render do
  use Ecto.Schema
  import EctoEnum

  alias MultiTrackListening.Mixes.Mix

  defenum(StatusEnum, requested: 0, in_progress: 1, finished: 2, error: 3, canceled: 4, aborted: 5)

  schema "mix_renders" do
    field :result_file_uuid, :string
    field :status, StatusEnum, default: :requested

    belongs_to :mix, Mix

    timestamps()
  end
end
