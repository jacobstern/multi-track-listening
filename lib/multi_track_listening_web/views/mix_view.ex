defmodule MultiTrackListeningWeb.MixView do
  use MultiTrackListeningWeb, :view

  def render("scripts.track-one.html", assigns) do
    render_script(assigns.conn, "track-upload.js")
  end
end
