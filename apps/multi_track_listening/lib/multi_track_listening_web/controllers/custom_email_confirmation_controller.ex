defmodule MultiTrackListeningWeb.CustomEmailConfirmationController do
  use MultiTrackListeningWeb, :controller

  alias Plug.Conn
  alias PowEmailConfirmation.Plug

  @spec process_show(Conn.t(), map()) :: {:ok | :error, map(), Conn.t()}
  def process_show(conn, %{"id" => token}), do: Plug.confirm_email(conn, token)

  def show(conn, %{"id" => token}) do
    case Plug.confirm_email(conn, token) do
      {:ok, _changeset, conn} ->
        conn
        |> put_flash(:info, "The email address has been confirmed. Please sign in to continue.")
        |> redirect(to: redirect_to(conn))

      {:error, _changeset, conn} ->
        conn
        |> put_flash(:error, "The email address couldn't be confirmed.")
        |> redirect(to: redirect_to(conn))
    end
  end

  defp redirect_to(conn) do
    case Pow.Plug.current_user(conn) do
      nil ->
        case Map.get(conn.params, "intent") do
          nil -> Routes.pow_session_path(conn, :new)
          intent -> Routes.pow_session_path(conn, :new, intent: intent)
        end

      _user ->
        Routes.pow_registration_path(conn, :edit)
    end
  end
end
