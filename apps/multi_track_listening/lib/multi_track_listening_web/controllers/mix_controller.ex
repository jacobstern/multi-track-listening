defmodule MultiTrackListeningWeb.MixController do
  use MultiTrackListeningWeb, :controller

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

    case Mixes.persist_track_upload(params) do
      {:ok, track} ->
        updated = Mixes.update_track_two(mix, track)
        redirect(conn, to: Routes.mix_path(conn, :finalize, updated))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "track-two.html", mix: mix, changeset: changeset)
    end
  end

  def finalize(conn, %{"id" => id}) do
    mix = Mixes.get_mix!(id)
    render(conn, "finalize.html", client_uuid: mix.track_one.client_uuid)
  end
end
