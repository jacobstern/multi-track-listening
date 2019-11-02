defmodule MultiTrackListeningWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  alias MultiTrackListeningWeb.Router.Helpers, as: Routes

  defp intent_path_or_home(conn) do
    intent = Map.get(conn.params, "intent")

    if intent, do: intent, else: Routes.home_path(conn, :index)
  end

  @impl true
  def after_sign_in_path(conn), do: intent_path_or_home(conn)

  @impl true
  def after_registration_path(conn), do: intent_path_or_home(conn)

  @impl true
  def url_for(
        conn,
        PowEmailConfirmation.Phoenix.ConfirmationController,
        :show,
        [token],
        _query_params
      ) do
    intent = Map.get(conn.params, "intent")

    if intent do
      Routes.custom_email_confirmation_url(conn, :show, token, intent: intent)
    else
      Routes.pow_email_confirmation_confirmation_url(conn, :show, token)
    end
  end

  @impl true
  def url_for(conn, plug, verb, vars, query_params) do
    Pow.Phoenix.Routes.url_for(conn, plug, verb, vars, query_params)
  end
end
