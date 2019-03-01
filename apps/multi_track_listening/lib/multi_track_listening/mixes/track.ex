defmodule MultiTrackListening.Mixes.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias MultiTrackListening.Storage

  @type t :: %__MODULE__{
          name: String.t(),
          client_uuid: String.t(),
          file_uuid: Storage.uuid_t()
        }

  embedded_schema do
    field(:name, :string)
    field(:client_uuid, :string)
    field(:file_uuid, :string)
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:name, :client_uuid, :file_uuid])
    |> validate_required([:name, :file_uuid])
  end
end
