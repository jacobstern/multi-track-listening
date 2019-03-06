defmodule MultiTrackListening.Mixes do
  @moduledoc """
  The Mixes context.
  """

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo
  alias MultiTrackListening.Storage
  alias MultiTrackListening.PublishedMixes
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

  def create_render(%Mix{parameters: parameters} = mix) do
    track_one_file = Storage.duplicate_file!(mix.track_one.file_uuid)
    track_two_file = Storage.duplicate_file!(mix.track_two.file_uuid)

    render =
      Repo.insert!(%Render{
        mix: mix,
        track_one_file_uuid: track_one_file,
        track_two_file_uuid: track_two_file,
        mix_duration: parameters.mix_duration,
        track_one_start: parameters.track_one_start,
        track_two_start: parameters.track_two_start,
        track_one_name: mix.track_one.name,
        track_two_name: mix.track_two.name
      })

    Honeydew.async({:do_render, [render]}, :mix_render_queue)

    render
  end

  @spec get_render!(integer) :: Render.t()
  def get_render!(render_id) do
    Repo.get!(Render, render_id) |> Repo.preload(:mix)
  end

  @spec get_mix_render!(integer, integer) :: Render.t()
  def get_mix_render!(mix_id, render_id) do
    Repo.get_by!(Render, mix_id: mix_id, id: render_id) |> Repo.preload(:mix)
  end

  @spec update_render_internal(Render.t(), keyword() | %{optional(atom()) => any()}) :: Render.t()
  def update_render_internal(render, updates) do
    Ecto.Changeset.change(render, updates) |> Repo.update!() |> Repo.preload(:mix)
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

  defp persist_track_upload(attrs) do
    case TrackUpload.changeset(%TrackUpload{}, attrs) |> Ecto.Changeset.apply_action(:insert) do
      result = {:error, %Ecto.Changeset{}} ->
        result

      {:ok, %TrackUpload{file: file, name: name, client_uuid: client_uuid}} ->
        uuid = Storage.upload_file!(file.path, file.content_type)
        {:ok, %Track{file_uuid: uuid, name: name, client_uuid: client_uuid}}
    end
  end

  @spec change_track_upload() :: Ecto.Changeset.t()
  def change_track_upload() do
    TrackUpload.changeset(%TrackUpload{}, %{})
  end

  @spec attach_track_one(Mix.t(), any()) :: {:ok, Mix.t()} | {:error, Ecto.Changeset.t()}
  def attach_track_one(mix = %Mix{}, track_upload) do
    with {:ok, track} <- persist_track_upload(track_upload) do
      updated = Repo.update!(Ecto.Changeset.change(mix, track_one: track))

      if not is_nil(mix.track_one) do
        Storage.delete_file!(mix.track_one.file_uuid)
      end

      {:ok, updated}
    end
  end

  @spec attach_track_two(Mix.t(), any()) :: {:ok, Mix.t()} | {:error, Ecto.Changeset.t()}
  def attach_track_two(mix, track_upload) do
    with {:ok, track} <- persist_track_upload(track_upload) do
      updated = Repo.update!(Ecto.Changeset.change(mix, track_two: track))

      if not is_nil(mix.track_two) do
        Storage.delete_file!(mix.track_two.file_uuid)
      end

      {:ok, updated}
    end
  end

  @spec publish_mix(Render.t()) :: PublishedMix.t()
  def publish_mix(render = %Render{mix: mix, result_file_uuid: result_file})
      when is_binary(result_file) do
    audio_file = Storage.duplicate_file!(result_file)

    published =
      PublishedMixes.create_published_mix_internal(
        audio_file: audio_file,
        track_one_name: render.track_one_name,
        track_two_name: render.track_two_name
      )

    Ecto.Changeset.change(mix, published_mix_id: published.id) |> Repo.update!()
    published
  end
end
