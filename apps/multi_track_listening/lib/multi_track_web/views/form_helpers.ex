defmodule MultiTrackWeb.FormHelpers do
  use Phoenix.HTML
  import MultiTrackWeb.ErrorHelpers

  defp field_helper(form, field, label_text, input) do
    content_tag :div, class: "field" do
      [
        label(form, field, label_text, class: "label"),
        content_tag :div, class: "field-body" do
          content_tag(:div, input, class: "control")
        end,
        error_tag(form, field)
      ]
    end
  end

  def text_field(form, field, label_text, input_attrs \\ []) do
    field_helper(
      form,
      field,
      label_text,
      text_input(form, field, Keyword.merge([class: "input"], input_attrs))
    )
  end

  def password_field(form, field, label_text, input_attrs \\ []) do
    field_helper(
      form,
      field,
      label_text,
      password_input(form, field, Keyword.merge([class: "input"], input_attrs))
    )
  end
end
