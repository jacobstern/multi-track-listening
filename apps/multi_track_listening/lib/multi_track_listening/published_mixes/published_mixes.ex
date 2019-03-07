defmodule MultiTrackListening.PublishedMixes do
  @moduledoc """
  The PublishedMixes context.
  """

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo

  alias MultiTrackListening.PublishedMixes.PublishedMix

  @doc """
  Returns the list of published_mixes.

  ## Examples

      iex> list_published_mixes()
      [%PublishedMix{}, ...]

  """
  def list_published_mixes do
    Repo.all(PublishedMix)
  end

  @spec get_published_mix(integer) :: PublishedMix.t() | nil
  def get_published_mix(id), do: Repo.get(PublishedMix, id)

  @doc """
  Gets a single published_mix.

  Raises `Ecto.NoResultsError` if the Published mix does not exist.

  ## Examples

      iex> get_published_mix!(123)
      %PublishedMix{}

      iex> get_published_mix!(456)
      ** (Ecto.NoResultsError)

  """
  def get_published_mix!(id), do: Repo.get!(PublishedMix, id)

  @spec create_published_mix_internal(keyword() | %{optional(atom()) => any()}) ::
          PublishedMix.t()
  def create_published_mix_internal(attrs) do
    Ecto.Changeset.change(%PublishedMix{}, attrs) |> Repo.insert!()
  end

  @doc """
  Deletes a PublishedMix.

  ## Examples

      iex> delete_published_mix(published_mix)
      {:ok, %PublishedMix{}}

      iex> delete_published_mix(published_mix)
      {:error, %Ecto.Changeset{}}

  """
  def delete_published_mix(%PublishedMix{} = published_mix) do
    Repo.delete(published_mix)
  end
end
