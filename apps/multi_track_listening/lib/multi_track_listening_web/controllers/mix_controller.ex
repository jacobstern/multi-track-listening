defmodule MultiTrackListeningWeb.MixController do
  use MultiTrackListeningWeb, :controller

  alias MultiTrackListeningWeb.{Endpoint, MixView}
  alias MultiTrackListening.Mixes

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

    # TODO: update_track_two and persist_track_upload should be the same call
    case Mixes.persist_track_upload(params) do
      {:ok, track} ->
        updated = Mixes.update_track_two(mix, track)
        redirect(conn, to: Routes.mix_path(conn, :parameters, updated))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-two.html", mix: mix, changeset: changeset)
    end
  end

  defp render_parameters_page(conn, mix, changeset) do
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

  def parameters(conn, %{"id" => id}) do
    mix = Mixes.get_mix!(id)
    changeset = Mixes.change_mix(mix)
    render_parameters_page(conn, mix, changeset)
  end

  def create_mix_render(conn, %{"id" => id, "mix" => params}) do
    mix = Mixes.get_mix!(id)

    with {:ok, mix} <- Mixes.update_mix(mix, params) do
        mix_render = Mixes.create_render(mix)

        on_update = fn updated ->
          payload = MixView.render("mix-render.json", mix_render: updated)
          Endpoint.broadcast!("mix_renders:#{updated.id}", "update", payload)
        end

        Mixes.start_render_worker(mix, mix_render, on_update)

      redirect(conn, to: Routes.mix_path(conn, :mix_render, mix.id, mix_render.id))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "parameters.html", mix: mix, changeset: changeset)
    end
  end

  def mix_render(conn, %{"id" => id, "render_id" => render_id}) do
    mix = Mixes.get_mix!(id)
    mix_render = Mixes.get_mix_render!(id, render_id)
    render(conn, "mix-render.html", mix: mix, mix_render: mix_render)
  end
end
