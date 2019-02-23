defmodule MultiTrackListening.Mixes do
  @moduledoc """
  The Mixes context.
  """

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage

  alias MultiTrackListening.Mixes.{Mix, TrackUpload, Track, Render}

  @doc """
  Gets a single mix.

  Raises `Ecto.NoResultsError` if the Mix does not exist.

  ## Examples

      iex> get_mix!(123)
      %Mix{}

      iex> get_mix!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mix!(id), do: Repo.get!(Mix, id) |> Repo.preload(:parameters)

  @doc """
  Creates a mix.

  ## Examples

      iex> create_mix(%{field: value})
      {:ok, %Mix{}}

      iex> create_mix(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mix(attrs \\ %{}) do
    %Mix{}
    |> Mix.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_mix_default!() :: Ecto.Schema.t()
  def create_mix_default!() do
    Repo.insert!(%Mix{})
  end

  @doc """
  Updates a mix.

  ## Examples

      iex> update_mix(mix, %{field: new_value})
      {:ok, %Mix{}}

      iex> update_mix(mix, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mix(%Mix{} = mix, attrs) do
    mix
    |> Mix.changeset(attrs)
    |> Repo.update()
  end

  def start_render(%Mix{} = mix) do
    render = Repo.insert!(%Render{mix: mix})
    render
  end

  def get_current_render(%Mix{id: mix_id}) do
    from(r in Render, where: r.mix_id == ^mix_id, order_by: [desc: r.inserted_at], limit: 1)
    |> Repo.one()
  end

  @doc """
  Deletes a Mix.

  ## Examples

      iex> delete_mix(mix)
      {:ok, %Mix{}}

      iex> delete_mix(mix)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mix(%Mix{} = mix) do
    Repo.delete(mix)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mix changes.

  ## Examples

      iex> change_mix(mix)
      %Ecto.Changeset{source: %Mix{}}

  """
  def change_mix(%Mix{} = mix) do
    Mix.changeset(mix, %{})
  end

  @spec persist_track_upload(map()) ::
          {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def persist_track_upload(attrs) do
    case TrackUpload.changeset(%TrackUpload{}, attrs) |> Ecto.Changeset.apply_action(:insert) do
      result = {:error, %Ecto.Changeset{}} ->
        result

      {:ok, %TrackUpload{file: file, name: name, client_uuid: client_uuid}} ->
        uuid = Storage.persist_file(file.path, file.content_type)
        {:ok, %Track{file_uuid: uuid, name: name, client_uuid: client_uuid}}
    end
  end

  @spec change_track_upload() :: Ecto.Changeset.t()
  def change_track_upload() do
    TrackUpload.changeset(%TrackUpload{}, %{})
  end

  @spec update_track_one(Mix.t(), Track.t()) :: Mix.t()
  def update_track_one(%Mix{} = mix, %Track{} = track) do
    updated = Repo.update!(Ecto.Changeset.change(mix, track_one: track))

    if not is_nil(mix.track_one) do
      Storage.delete_file(mix.track_one.file_uuid)
    end

    updated
  end

  @spec update_track_two(Mix.t(), Track.t()) :: Mix.t()
  def update_track_two(%Mix{} = mix, %Track{} = track) do
    updated = Repo.update!(Ecto.Changeset.change(mix, track_two: track))

    if not is_nil(mix.track_two) do
      Storage.delete_file(mix.track_two.file_uuid)
    end

    updated
  end
end
