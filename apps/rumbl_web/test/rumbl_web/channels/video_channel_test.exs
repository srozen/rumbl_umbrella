defmodule RumblWeb.VideoChannelTest do
  use RumblWeb.ChannelCase
  alias Rumbl.AccountsFixtures
  alias Rumbl.MultimediaFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    video = MultimediaFixtures.video_fixture(user)
    token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    {:ok, socket} = connect(RumblWeb.UserSocket, %{"token" => token})

    on_exit(fn ->
      :timer.sleep(1)
      for pid <- RumblWeb.Presence.fetchers_pids()  do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end
    end)

    %{socket: socket, user: user, video: video}
  end

  test "join replies with video annotations", %{socket: socket, video: vid, user: user} do
    for body <- ~w(one two) do
      Rumbl.Multimedia.annotate_video(user, vid.id, %{body: body, at: 0})
    end

    {:ok, reply, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})

    assert socket.assigns.video_id == vid.id
    assert %{annotations: [%{body: "one"}, %{body: "two"}]} = reply
  end

  test "inserting new annotations", %{socket: socket, video: vid} do
    {:ok, _reply, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    ref = push socket, "new_annotation", %{body: "the body", at: 0}
    assert_reply ref, :ok, %{}
    assert_broadcast "new_annotation", %{}
  end

  test "new annotations triggers InfoSys", %{socket: socket, video: vid} do
    AccountsFixtures.user_fixture(%{username: "wolfram"})
    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    ref = push socket, "new_annotation", %{body: "1 + 1", at: 123}
    assert_reply ref, :ok, %{}
    assert_broadcast "new_annotation", %{body: "1 + 1", at: 123}
    assert_broadcast "new_annotation", %{body: "2", at: 123}
  end
end
