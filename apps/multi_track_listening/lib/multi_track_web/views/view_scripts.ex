defmodule MultiTrackWeb.ViewScripts do
  use Phoenix.HTML
  alias MultiTrackWeb.Router.Helpers, as: Routes

  def render_script_tag(conn, file_name) do
    path = Path.join("/js", file_name)
    content_tag(:script, nil, src: Routes.static_path(conn, path))
  end
end
