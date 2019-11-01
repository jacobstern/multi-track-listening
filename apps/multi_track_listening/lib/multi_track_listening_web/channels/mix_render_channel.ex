defmodule MultiTrackListeningWeb.MixRenderChannel do
  use MultiTrackListeningWeb, :channel

  alias MultiTrackListening.Mixes
  alias MultiTrackListeningWeb.MixView

  def join("mix_renders:" <> render_id, _payload, socket) do
    render = Mixes.get_render!(render_id)
    payload = MixView.render("mix-render.json", mix_render: render)
    {:ok, payload, assign(socket, :render_id, render.id)}
  end
end
