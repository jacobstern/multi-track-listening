defmodule MultiTrackWeb.FormHelpers do
  use Phoenix.HTML
  import MultiTrackWeb.ErrorHelpers

  defp field_helper(form, field, label_text, input_attrs, input_factory) do
    base_classes =
      if Keyword.get(form.errors, field) do
        "input is-danger"
      else
        "input"
      end

    attrs = Keyword.merge([class: base_classes], input_attrs)

    content_tag :div, class: "field" do
      [
        label(form, field, label_text, class: "label"),
        content_tag :div, class: "field-body" do
          content_tag(:div, input_factory.(form, field, attrs), class: "control")
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
      input_attrs,
      &text_input/3
    )
  end

  def password_field(form, field, label_text, input_attrs \\ []) do
    field_helper(
      form,
      field,
      label_text,
      input_attrs,
      &password_input/3
    )
  end
end
