defmodule MultiTrackListening.PublishedMixesTest do
  use MultiTrackListening.DataCase

  alias MultiTrackListening.PublishedMixes

  describe "published_mixes" do
    alias MultiTrackListening.PublishedMixes.PublishedMix

    @valid_attrs %{audio_file: "some audio_file", track_one_name: "some track_one_name", track_two_name: "some track_two_name"}
    @update_attrs %{audio_file: "some updated audio_file", track_one_name: "some updated track_one_name", track_two_name: "some updated track_two_name"}
    @invalid_attrs %{audio_file: nil, track_one_name: nil, track_two_name: nil}

    def published_mix_fixture(attrs \\ %{}) do
      {:ok, published_mix} =
        attrs
        |> Enum.into(@valid_attrs)
        |> PublishedMixes.create_published_mix()

      published_mix
    end

    test "list_published_mixes/0 returns all published_mixes" do
      published_mix = published_mix_fixture()
      assert PublishedMixes.list_published_mixes() == [published_mix]
    end

    test "get_published_mix!/1 returns the published_mix with given id" do
      published_mix = published_mix_fixture()
      assert PublishedMixes.get_published_mix!(published_mix.id) == published_mix
    end

    test "create_published_mix/1 with valid data creates a published_mix" do
      assert {:ok, %PublishedMix{} = published_mix} = PublishedMixes.create_published_mix(@valid_attrs)
      assert published_mix.audio_file == "some audio_file"
      assert published_mix.track_one_name == "some track_one_name"
      assert published_mix.track_two_name == "some track_two_name"
    end

    test "create_published_mix/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PublishedMixes.create_published_mix(@invalid_attrs)
    end

    test "update_published_mix/2 with valid data updates the published_mix" do
      published_mix = published_mix_fixture()
      assert {:ok, %PublishedMix{} = published_mix} = PublishedMixes.update_published_mix(published_mix, @update_attrs)
      assert published_mix.audio_file == "some updated audio_file"
      assert published_mix.track_one_name == "some updated track_one_name"
      assert published_mix.track_two_name == "some updated track_two_name"
    end

    test "update_published_mix/2 with invalid data returns error changeset" do
      published_mix = published_mix_fixture()
      assert {:error, %Ecto.Changeset{}} = PublishedMixes.update_published_mix(published_mix, @invalid_attrs)
      assert published_mix == PublishedMixes.get_published_mix!(published_mix.id)
    end

    test "delete_published_mix/1 deletes the published_mix" do
      published_mix = published_mix_fixture()
      assert {:ok, %PublishedMix{}} = PublishedMixes.delete_published_mix(published_mix)
      assert_raise Ecto.NoResultsError, fn -> PublishedMixes.get_published_mix!(published_mix.id) end
    end

    test "change_published_mix/1 returns a published_mix changeset" do
      published_mix = published_mix_fixture()
      assert %Ecto.Changeset{} = PublishedMixes.change_published_mix(published_mix)
    end
  end
end
