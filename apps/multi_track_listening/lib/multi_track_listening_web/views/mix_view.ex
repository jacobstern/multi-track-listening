defmodule MultiTrackListeningWeb.MixView do
  use MultiTrackListeningWeb, :view

  def render("scripts.track-one.html", assigns) do
    render_script_tag(assigns.conn, "track-upload.js")
  end

  def render("scripts.track-two.html", assigns) do
    render_script_tag(assigns.conn, "track-upload.js")
  end

  def render("scripts.finalize.html", assigns) do
    render_script_tag(assigns.conn, "finalize-mix.js")
  end
end
