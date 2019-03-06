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

  @doc """
  Creates a published_mix.

  ## Examples

      iex> create_published_mix(%{field: value})
      {:ok, %PublishedMix{}}

      iex> create_published_mix(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_published_mix(attrs \\ %{}) do
    %PublishedMix{}
    |> PublishedMix.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a published_mix.

  ## Examples

      iex> update_published_mix(published_mix, %{field: new_value})
      {:ok, %PublishedMix{}}

      iex> update_published_mix(published_mix, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_published_mix(%PublishedMix{} = published_mix, attrs) do
    published_mix
    |> PublishedMix.changeset(attrs)
    |> Repo.update()
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking published_mix changes.

  ## Examples

      iex> change_published_mix(published_mix)
      %Ecto.Changeset{source: %PublishedMix{}}

  """
  def change_published_mix(%PublishedMix{} = published_mix) do
    PublishedMix.changeset(published_mix, %{})
  end
end
