defmodule MultiTrackListening.ListensTest do
  use MultiTrackListening.DataCase

  alias MultiTrackListening.Listens

  describe "listens" do
    alias MultiTrackListening.Listens.Listen

    @valid_attrs %{audio_file_uuid: "some audio_file_uuid", track_one_name: "some track_one_name", track_two_name: "some track_two_name"}
    @update_attrs %{audio_file_uuid: "some updated audio_file_uuid", track_one_name: "some updated track_one_name", track_two_name: "some updated track_two_name"}
    @invalid_attrs %{audio_file_uuid: nil, track_one_name: nil, track_two_name: nil}

    def listen_fixture(attrs \\ %{}) do
      {:ok, listen} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Listens.create_listen()

      listen
    end

    test "list_listens/0 returns all listens" do
      listen = listen_fixture()
      assert Listens.list_listens() == [listen]
    end

    test "get_listen!/1 returns the listen with given id" do
      listen = listen_fixture()
      assert Listens.get_listen!(listen.id) == listen
    end

    test "create_listen/1 with valid data creates a listen" do
      assert {:ok, %Listen{} = listen} = Listens.create_listen(@valid_attrs)
      assert listen.audio_file_uuid == "some audio_file_uuid"
      assert listen.track_one_name == "some track_one_name"
      assert listen.track_two_name == "some track_two_name"
    end

    test "create_listen/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Listens.create_listen(@invalid_attrs)
    end

    test "update_listen/2 with valid data updates the listen" do
      listen = listen_fixture()
      assert {:ok, %Listen{} = listen} = Listens.update_listen(listen, @update_attrs)
      assert listen.audio_file_uuid == "some updated audio_file_uuid"
      assert listen.track_one_name == "some updated track_one_name"
      assert listen.track_two_name == "some updated track_two_name"
    end

    test "update_listen/2 with invalid data returns error changeset" do
      listen = listen_fixture()
      assert {:error, %Ecto.Changeset{}} = Listens.update_listen(listen, @invalid_attrs)
      assert listen == Listens.get_listen!(listen.id)
    end

    test "delete_listen/1 deletes the listen" do
      listen = listen_fixture()
      assert {:ok, %Listen{}} = Listens.delete_listen(listen)
      assert_raise Ecto.NoResultsError, fn -> Listens.get_listen!(listen.id) end
    end

    test "change_listen/1 returns a listen changeset" do
      listen = listen_fixture()
      assert %Ecto.Changeset{} = Listens.change_listen(listen)
    end
  end
end
