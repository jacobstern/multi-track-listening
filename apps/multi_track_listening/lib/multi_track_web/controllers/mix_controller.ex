defmodule MultiTrackWeb.MixController do
  use MultiTrackWeb, :controller

  alias MultiTrackListening.Mixes

  def create(conn, _params) do
    mix = Mixes.create_mix_default!()
    redirect(conn, to: Routes.mix_path(conn, :new_track_one, mix))
  end

  def new_track_one(conn, _params) do
    mix = conn.assigns[:mix]
    changeset = Mixes.change_track_upload()
    render(conn, "track-one.html", mix: mix, changeset: changeset)
  end

  def create_track_one(conn, %{"track_upload" => params}) do
    mix = conn.assigns[:mix]

    case Mixes.attach_track_one(mix, params) do
      {:ok, updated} ->
        redirect(conn, to: Routes.mix_path(conn, :parameters, updated))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-one.html", mix: mix, changeset: changeset)
    end
  end

  def new_track_two(conn, _params) do
    mix = conn.assigns[:mix]
    changeset = Mixes.change_track_upload()
    render(conn, "track-two.html", mix: mix, changeset: changeset)
  end

  def create_track_two(conn, %{"track_upload" => params}) do
    mix = conn.assigns[:mix]

    case Mixes.attach_track_two(mix, params) do
      {:ok, updated} ->
        redirect(conn, to: Routes.mix_path(conn, :parameters, updated))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-two.html", mix: mix, changeset: changeset)
    end
  end

  def parameters(conn, _params) do
    mix = conn.assigns[:mix]
    changeset = Mixes.change_mix(mix)

    cond do
      is_nil(mix.track_one) ->
        redirect(conn, to: Routes.mix_path(conn, :new_track_one, mix))

      is_nil(mix.track_two) ->
        redirect(conn, to: Routes.mix_path(conn, :new_track_two, mix))

      true ->
        render(conn, "parameters.html",
          mix: mix,
          changeset: changeset
        )
    end
  end

  def create_mix_render(conn, %{"mix" => params}) do
    mix = conn.assigns[:mix]

    with {:ok, mix} <- Mixes.update_mix(mix, params) do
      mix_render = Mixes.create_render(mix)
      redirect(conn, to: Routes.mix_path(conn, :mix_render, mix.id, mix_render.id))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "parameters.html", mix: mix, changeset: changeset)
    end
  end

  def mix_render(conn, %{"render_id" => render_id}) do
    mix = conn.assigns[:mix]
    mix_render = Mixes.get_mix_render!(mix.id, render_id)
    render(conn, "mix-render.html", mix: mix, mix_render: mix_render)
  end

  def publish(conn, %{"render_id" => render_id}) do
    mix = conn.assigns[:mix]
    mix_render = Mixes.get_mix_render!(mix.id, render_id)
    published_mix = Mixes.publish_mix(mix_render)
    redirect(conn, to: Routes.published_mix_path(conn, :published_mix, published_mix))
  end
end
