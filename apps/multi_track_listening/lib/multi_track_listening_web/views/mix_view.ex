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

  def render("scripts.mix-render.html", assigns) do
    render_script_tag(assigns.conn, "mix-render.js")
  end

  def display_mix_render_status(render_status) do
    strings = %{
      requested: "Requested",
      in_progress: "In progress",
      finished: "Finished",
      error: "Error",
      canceled: "Canceled",
      aborted: "Aborted"
    }

    strings[render_status]
  end
end
