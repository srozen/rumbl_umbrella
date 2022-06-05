defmodule RumblWeb.VideoControllerTest do
  use RumblWeb.ConnCase, async: true

  import Rumbl.MultimediaFixtures
  import Rumbl.AccountsFixtures
  alias Rumbl.Multimedia

  @create_attrs %{description: "some description", title: "some title", url: "some url"}
  @update_attrs %{description: "some updated description", title: "some updated title", url: "some updated url"}
  @invalid_attrs %{description: nil, title: nil, url: nil}

  describe "when user is not authenticated" do
    test "he cannot access videos", %{conn: conn} do
      Enum.each([
        get(conn, Routes.video_path(conn, :index)),
        get(conn, Routes.video_path(conn, :new)),
        get(conn, Routes.video_path(conn, :show, "123")),
        get(conn, Routes.video_path(conn, :edit, "123", %{})),
        get(conn, Routes.video_path(conn, :update, "123", %{})),
        get(conn, Routes.video_path(conn, :create, %{})),
        get(conn, Routes.video_path(conn, :delete, "123")),
      ], fn conn ->
        assert html_response(conn, 302)
        assert conn.halted
      end
      )
    end
  end

  describe "when user is authenticated" do
    setup :register_and_log_in_user

    test "lists all videos on index", %{conn: conn, user: user} do
      %{video: video} = create_video(user)
      other_video = video_fixture(user_fixture(), %{title: "I belong to someone else"})
      conn = get(conn, Routes.video_path(conn, :index))
      response = html_response(conn, 200)
      assert response =~ "Listing Videos"
      assert response =~ video.title
      refute response =~ other_video.title
    end

    test "show create form", %{conn: conn} do
      conn = get(conn, Routes.video_path(conn, :new))
      assert html_response(conn, 200) =~ "New Video"
    end

    test "create a video and redirects to show when data is valid", %{conn: conn, user: user} do
      conn = post(conn, Routes.video_path(conn, :create), video: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.video_path(conn, :show, id)

      conn = get(conn, Routes.video_path(conn, :show, id))
      assert Multimedia.get_video!(id).user_id == user.id
      assert html_response(conn, 200) =~ "Show Video"
    end

    test "does not create a video and renders errors when data invalid", %{conn: conn} do
      initial_videos_count = count_videos()
      conn = post(conn, Routes.video_path(conn, :create), video: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Video"
      assert html_response(conn, 200) =~ "check the errors"
      assert initial_videos_count == count_videos()
    end

    test "edit renders form for editing chosen video", %{conn: conn, user: user} do
      video = video_fixture(user)
      conn = get(conn, Routes.video_path(conn, :edit, video))
      assert html_response(conn, 200) =~ "Edit Video"
    end

    test "effectively deletes a video", %{conn: conn, user: user} do
      video = video_fixture(user)
      video_count = count_videos()
      conn = delete(conn, Routes.video_path(conn, :delete, video))
      assert redirected_to(conn) == Routes.video_path(conn, :index)
      assert video_count > count_videos()
    end

    test "update redirects when data is valid", %{conn: conn, user: user} do
      video = video_fixture(user)
      conn = put(conn, Routes.video_path(conn, :update, video), video: @update_attrs)
      updated_video = Multimedia.get_video!(video.id)
      assert redirected_to(conn) == Routes.video_path(conn, :show, updated_video)

      conn = get(conn, Routes.video_path(conn, :show, video))
      assert html_response(conn, 200) =~ @update_attrs.description
    end

    test "update renders errors when data is invalid", %{conn: conn, user: user} do
      video = video_fixture(user)
      conn = put(conn, Routes.video_path(conn, :update, video), video: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Video"
    end

    test "authorizes actions against access by other users", %{conn: conn} do
      other_user = user_fixture()
      video = video_fixture(other_user)

      assert_error_sent :not_found, fn ->
        get(conn, Routes.video_path(conn, :show, video))
      end

      assert_error_sent :not_found, fn ->
        delete(conn, Routes.video_path(conn, :delete, video))
      end

      assert_error_sent :not_found, fn ->
        put(conn, Routes.video_path(conn, :update, video, video: @update_attrs))
      end
    end
  end

  defp create_video(owner) do
    video = video_fixture(owner)
    %{video: video}
  end

  defp count_videos() do
    Multimedia.list_videos()
    |> Enum.count()
  end
end
