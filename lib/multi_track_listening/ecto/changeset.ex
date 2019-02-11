defmodule MultiTrackListening.Ecto.Changeset do
  import Ecto.Changeset

  @spec validate_content_type_inclusion(Ecto.Changeset.t(), atom(), list(String.t()), Keyword.t()) ::
          Ecto.Changeset.t()
  def validate_content_type_inclusion(changeset, field, content_types, options \\ []) do
    validate_change(changeset, field, fn _, %Plug.Upload{content_type: content_type} ->
      if Enum.member?(content_types, content_type) do
        []
      else
        [{field, options[:message] || "invalid content type #{content_type}"}]
      end
    end)
  end
end
