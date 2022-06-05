defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel
  alias Rumbl.{Accounts, Multimedia}
  alias RumblWeb.{AnnotationView, Presence}

  @impl true
  def join("video:lobby", _message, socket) do
    {:ok, socket}
  end

  @impl true
  def join("videos:" <> video_id, params, socket) do
    if params && authorized?(params) do
      send(self(), :after_join)
      last_seen_id = params["last_seen_id"] || 0
      video_id = String.to_integer(video_id)
      video = Multimedia.get_video!(video_id)

      annotations =
        video
        |> Multimedia.list_video_annotations(last_seen_id)
        |> Phoenix.View.render_many(AnnotationView, "annotation.json")

      {:ok, %{annotations: annotations}, assign(socket, :video_id, video_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_annotation", params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    case Multimedia.annotate_video(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        broadcast!(socket, "new_annotation", %{
          id: annotation.id,
          user: RumblWeb.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at: annotation.at
        })

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

    # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (video:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(
      socket,
      socket.assigns.user_id,
      %{
        online_at: inspect(System.system_time(:second)),
        device: "browser"
      }
    )

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
