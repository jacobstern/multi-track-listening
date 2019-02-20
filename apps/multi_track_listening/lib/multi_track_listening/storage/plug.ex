defmodule MultiTrackListening.Storage.Plug do
  @behaviour Plug

  def init(_opts) do
    Plug.Static.init(at: "/uploads", from: "/media")
  end

  defdelegate call(conn, options), to: Plug.Static
end
