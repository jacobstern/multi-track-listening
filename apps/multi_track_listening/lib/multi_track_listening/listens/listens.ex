defmodule MultiTrackListening.Listens do
  @moduledoc """
  The Listens context.
  """

  import Ecto.Query, warn: false
  alias MultiTrackListening.Repo

  alias MultiTrackListening.Listens.Listen

  @doc """
  Returns the list of listens.

  ## Examples

      iex> list_listens()
      [%Listen{}, ...]

  """
  def list_listens do
    Repo.all(Listen)
  end

  @doc """
  Gets a single listen.

  Raises `Ecto.NoResultsError` if the Listen does not exist.

  ## Examples

      iex> get_listen!(123)
      %Listen{}

      iex> get_listen!(456)
      ** (Ecto.NoResultsError)

  """
  def get_listen!(id), do: Repo.get!(Listen, id)

  @doc """
  Creates a listen.

  ## Examples

      iex> create_listen(%{field: value})
      {:ok, %Listen{}}

      iex> create_listen(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_listen(attrs \\ %{}) do
    %Listen{}
    |> Listen.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a listen.

  ## Examples

      iex> update_listen(listen, %{field: new_value})
      {:ok, %Listen{}}

      iex> update_listen(listen, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_listen(%Listen{} = listen, attrs) do
    listen
    |> Listen.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Listen.

  ## Examples

      iex> delete_listen(listen)
      {:ok, %Listen{}}

      iex> delete_listen(listen)
      {:error, %Ecto.Changeset{}}

  """
  def delete_listen(%Listen{} = listen) do
    Repo.delete(listen)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking listen changes.

  ## Examples

      iex> change_listen(listen)
      %Ecto.Changeset{source: %Listen{}}

  """
  def change_listen(%Listen{} = listen) do
    Listen.changeset(listen, %{})
  end
end
