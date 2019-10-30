defmodule MultiTrackListening.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()
    field :username, :string

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:username])
    |> Ecto.Changeset.validate_required([:username])
    |> Ecto.Changeset.unique_constraint(:username)
  end
end
