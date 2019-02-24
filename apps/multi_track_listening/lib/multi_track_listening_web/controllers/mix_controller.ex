defmodule MultiTrackListeningWeb.MixController do
  use MultiTrackListeningWeb, :controller

  alias MultiTrackListening.Mixes
  alias MultiTrackListening.Storage

  def create(conn, _params) do
    mix = Mixes.create_mix_default!()
    redirect(conn, to: Routes.mix_path(conn, :new_track_one, mix))
  end

  def new_track_one(conn, %{"id" => id}) do
    mix = Mixes.get_mix!(id)
    changeset = Mixes.change_track_upload()
    render(conn, "track-one.html", mix: mix, changeset: changeset)
  end

  def create_track_one(conn, %{"id" => id, "track_upload" => params}) do
    mix = Mixes.get_mix!(id)

    case Mixes.persist_track_upload(params) do
      {:ok, track} ->
        Mixes.update_track_one(mix, track)
        redirect(conn, to: Routes.mix_path(conn, :new_track_two, mix))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-one.html", mix: mix, changeset: changeset)
    end
  end

  def new_track_two(conn, %{"id" => id}) do
    mix = Mixes.get_mix!(id)
    changeset = Mixes.change_track_upload()
    render(conn, "track-two.html", mix: mix, changeset: changeset)
  end

  def create_track_two(conn, %{"id" => id, "track_upload" => params}) do
    mix = Mixes.get_mix!(id)

    case Mixes.persist_track_upload(params) do
      {:ok, track} ->
        updated = Mixes.update_track_two(mix, track)
        redirect(conn, to: Routes.mix_path(conn, :finalize, updated))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-two.html", mix: mix, changeset: changeset)
    end
  end

  defp render_finalize_page(conn, mix, changeset) do
    cond do
      is_nil(mix.track_one) ->
        redirect(conn, to: Routes.mix_path(conn, :new_track_one, mix))

      is_nil(mix.track_two) ->
        redirect(conn, to: Routes.mix_path(conn, :new_track_two, mix))

      true ->
        render(conn, "finalize.html",
          mix: mix,
          changeset: changeset
        )
    end
  end

  def finalize(conn, %{"id" => id}) do
    mix = Mixes.get_mix!(id)
    changeset = Mixes.change_mix(mix)
    render_finalize_page(conn, mix, changeset)
  end

  def create_mix_render(conn, %{"id" => id, "mix" => params}) do
    mix = Mixes.get_mix!(id)

    case Mixes.update_mix(mix, params) do
      {:ok, mix} ->
        mix_render = Mixes.start_render(mix)

        redirect(conn,
          to: Routes.mix_path(conn, :mix_render, mix.id, mix_render.id)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render_finalize_page(conn, mix, changeset)
    end
  end

  def mix_render(conn, %{"id" => id, "render_id" => render_id}) do
    mix = Mixes.get_mix!(id)
    mix_render = Mixes.get_mix_render!(id, render_id)
    render(conn, "mix-render.html", mix: mix, mix_render: mix_render)
  end
end
