defmodule MultiTrackListening.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  use Pow.Ecto.Schema,
    user_id_field: :username

  schema "users" do
    pow_user_fields()
    field :email, :string

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> cast(attrs, [:email])
    |> unique_constraint(:email)
    |> validate_change(:email, fn :email, email ->
      case Pow.Ecto.Schema.Changeset.validate_email(email) do
        :ok ->
          []

        {:error, reason} ->
          [email: {"has invalid format", reason: reason}]
      end
    end)
    |> validate_format(:username, ~r/^[a-z]+[a-z0-9_]*$/)
    |> validate_length(:username, min: 3, max: 20)
  end
end
