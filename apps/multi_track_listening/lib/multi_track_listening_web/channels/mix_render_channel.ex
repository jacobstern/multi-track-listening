defmodule MultiTrackListeningWeb.MixRenderChannel do
  use MultiTrackListeningWeb, :channel

  alias MultiTrackListening.Mixes

  def join("mix_renders:" <> render_id, _payload, socket) do
    render = Mixes.get_render!(render_id)
    {:ok, assign(socket, :render_id, render.id)}
  end

  def handle_in("latest", _payload, socket) do
    render = Mixes.get_render!(socket.assigns.render_id)
    {:reply, {:ok, %{"status" => inspect(render.status)}}, socket}
  end
end
