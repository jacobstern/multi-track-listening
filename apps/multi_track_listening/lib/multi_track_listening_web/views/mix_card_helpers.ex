defmodule MultiTrackListeningWeb.MixCardHelpers do
  use Phoenix.HTML

  def mix_card_author(published) do
    if published.author do
      # TODO: Link to profile
      published.author.username
    else
      "anonymous"
    end
  end
end
