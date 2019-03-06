defmodule MultiTrackWeb.Plugs.LoadMix do
  import Plug.Conn
  alias MultiTrackListening.Mixes

  def init(_), do: nil

  def call(conn = %Plug.Conn{params: %{"id" => id}}, _) do
    mix = Mixes.get_mix!(id)

    conn
    |> assign(:mix, mix)
  end
end
