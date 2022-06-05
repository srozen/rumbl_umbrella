defmodule Rumbl.MultimediaFixtures do
  alias Rumbl.Accounts
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rumbl.Multimedia` context.
  """

  @doc """
  Generate a video.
  """
  def video_fixture(%Accounts.User{} = user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        title: "some title",
        url: "some url"
      })

    {:ok, video} = Rumbl.Multimedia.create_video(user, attrs)

    video
  end
end
