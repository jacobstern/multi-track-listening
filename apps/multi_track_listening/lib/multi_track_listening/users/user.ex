defmodule MultiTrackListening.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  use Pow.Ecto.Schema,
    user_id_field: :username

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  schema "users" do
    pow_user_fields()
    field :email, :string

    timestamps()
  end

  defp validate_username_not_forbidden(changeset, field) do
    validate_change(changeset, field, fn ^field, username ->
      if username == "anonymous" do
        [username: "this username is reserved"]
      else
        []
      end
    end)
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_change(:email, fn :email, email ->
      case Pow.Ecto.Schema.Changeset.validate_email(email) do
        :ok ->
          []

        {:error, reason} ->
          [email: {"has invalid format", reason: reason}]
      end
    end)
    |> unique_constraint(:email)
    |> validate_format(:username, ~r/^[a-z]+[a-z0-9_]*$/)
    |> validate_length(:username, min: 3, max: 20)
    |> validate_username_not_forbidden(:username)
  end
end
