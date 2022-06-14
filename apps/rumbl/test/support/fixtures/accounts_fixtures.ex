defmodule Rumbl.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rumbl.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def random_username, do: for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: random_username(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Rumbl.Accounts.create_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
