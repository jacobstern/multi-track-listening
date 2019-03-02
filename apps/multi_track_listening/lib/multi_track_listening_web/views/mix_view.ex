defmodule MultiTrackWeb.MixView do
  use MultiTrackWeb, :view

  alias MultiTrackWeb.Endpoint
  alias MultiTrackWeb.Router.Helpers, as: Routes

  def render("scripts.track-one.html", assigns) do
    render_script_tag(assigns.conn, "track-upload.js")
  end

  def render("scripts.track-two.html", assigns) do
    render_script_tag(assigns.conn, "track-upload.js")
  end

  def render("scripts.parameters.html", assigns) do
    render_script_tag(assigns.conn, "mix-parameters.js")
  end

  def render("scripts.mix-render.html", assigns) do
    render_script_tag(assigns.conn, "mix-render.js")
  end

  def render("mix-render.json", %{mix_render: mix_render}) do
    %{
      status: mix_render.status,
      status_text: display_mix_render_status(mix_render.status),
      result_url: mix_render_result_url(mix_render)
    }
  end

  def mix_render_result_url(mix_render) do
    if mix_render.result_file_uuid do
      Routes.storage_url(Endpoint, :serve_file, mix_render.result_file_uuid)
    end
  end

  def display_mix_render_status(render_status) do
    %{
      finished: "Done! You can now post or download the mix.",
      error: "There was an error rendering this mix. Please try again later."
    }[render_status]
  end
end
