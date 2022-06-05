defmodule RumblWeb.UserController do
  use RumblWeb, :controller

  alias Rumbl.Accounts

  def index(conn, _params) do
    render(conn, "index.html", users: Accounts.get_users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end
end
