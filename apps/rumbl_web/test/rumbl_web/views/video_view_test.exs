defmodule RumblWeb.VideoViewTest do
  use RumblWeb.ConnCase, async: true
  import Phoenix.View

  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.{Video, Category}

  test "renders index.html", %{conn: conn} do
    videos = [
      %Video{id: "1", title: "Dogs"},
      %Video{id: "2", title: "Cats"}
    ]

    content = render_to_string(
      RumblWeb.VideoView,
      "index.html",
      conn: conn,
      videos: videos
    )

    assert String.contains?(content, "Listing Videos")

    for video <- videos do
      assert String.contains?(content, video.title)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = Multimedia.change_video(%Video{})
    categories = [%Category{id: 123, name: "Cats"}]

    content = render_to_string(
      RumblWeb.VideoView,
      "new.html",
      conn: conn,
      changeset: changeset,
      categories: categories
    )

    assert String.contains?(content, "New Video")
  end
end
