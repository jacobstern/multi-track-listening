defmodule MultiTrackListeningWeb.LayoutView do
  use MultiTrackListeningWeb, :view

  defp path_segments(path) do
    String.split(path, "/", trim: true)
  end

  defp active_path?(conn, path, exact) do
    if exact do
      conn.path_info == path_segments(path)
    else
      List.starts_with?(conn.path_info, path_segments(path))
    end
  end

  defp navbar_classes(is_active) do
    if is_active do
      ["navbar-item", "is-active"]
    else
      ["navbar-item"]
    end
  end

  def navbar_link(conn, text, path, opts \\ []) do
    classes =
      active_path?(conn, path, Keyword.get(opts, :exact, false))
      |> navbar_classes()
      |> Enum.join(" ")

    link(text, Keyword.merge([to: path, class: classes], opts))
  end
end
