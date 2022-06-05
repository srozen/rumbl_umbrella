defmodule RumblWeb.UserView do
  use RumblWeb, :view

  def email(%Rumbl.Accounts.User{email: email}) do
    email
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, username: user.email}
  end
end
