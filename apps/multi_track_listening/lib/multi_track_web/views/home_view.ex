defmodule MultiTrackWeb.HomeView do
  use MultiTrackWeb, :view

  def render("scripts.index.html", assigns) do
    render_script_tag(assigns.conn, "mix-card.js")
  end
end
