defmodule MultiTrackWeb.PublishedMixView do
  use MultiTrackWeb, :view

  def render("scripts.show.html", assigns) do
    render_script_tag(assigns.conn, "mix-card.js")
  end
end
