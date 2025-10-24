defmodule HanaShirabe.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HanaShirabe.Accounts` context.
  """

  import Ecto.Query

  alias HanaShirabe.{Accounts, AuditLog}
  alias HanaShirabe.Accounts.Scope

  def unique_member_email, do: "member#{System.unique_integer()}@example.com"
  def valid_member_password, do: "hello world!"

  def valid_member_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_member_email()
    })
  end

  def unconfirmed_member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> valid_member_attributes()
      |> Accounts.register_member(AuditLog.localhost!(:test))

    member
  end

  def member_fixture(attrs \\ %{}) do
    member = unconfirmed_member_fixture(attrs)

    token =
      extract_member_token(fn url ->
        Accounts.deliver_login_instructions(member, url)
      end)

    {:ok, {member, _expired_tokens}} =
      Accounts.login_member_by_magic_link(token)

    member
  end

  def member_scope_fixture do
    member = member_fixture()
    member_scope_fixture(member)
  end

  def member_scope_fixture(member) do
    Scope.for_member(member)
  end

  def set_password(member) do
    {:ok, {member, _expired_tokens}} =
      Accounts.update_member_password(member, %{password: valid_member_password()})

    member
  end

  def extract_member_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    HanaShirabe.Repo.update_all(
      from(t in Accounts.MemberToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_member_magic_link_token(member) do
    {encoded_token, member_token} = Accounts.MemberToken.build_email_token(member, "login")
    HanaShirabe.Repo.insert!(member_token)
    {encoded_token, member_token.token}
  end

  def offset_member_token(token, amount_to_add, unit) do
    dt = NaiveDateTime.add(NaiveDateTime.utc_now(:second), amount_to_add, unit)

    HanaShirabe.Repo.update_all(
      from(ut in Accounts.MemberToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
