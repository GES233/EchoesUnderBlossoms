defmodule HanaShirabe.AccountsFixtures do
  @moduledoc """
  此模块定义用于通过 `HanaShirabe.Accounts` 上下文创建实体的测试助手。
  """

  import Ecto.Query

  # require Config
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
      |> then(&Accounts.register_member(create_audit_log(), &1))

    member
  end

  def create_audit_log() do
    elixir_version = System.version()
    otp_version = :erlang.system_info(:otp_release)

    user_agent = "[Localhost] (Elixir#{elixir_version} /OTP #{otp_version})"

    struct!(AuditLog, %{
      ip_addr: {127, 0, 0, 1},
      user_agent: user_agent,
      member_id: nil
    })
  end

  def create_audit_log(member = %Accounts.Member{}) do
    %{create_audit_log() | member: member}
  end

  def member_fixture(attrs \\ %{}) do
    member = unconfirmed_member_fixture(attrs)

    token =
      extract_member_token(fn url ->
        Accounts.deliver_login_instructions(member, url)
      end)

    {:ok, {member, _expired_tokens}} =
      Accounts.log_in_and_log_by_magic_link(create_audit_log(), token)

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
      Accounts.update_member_password_with_log(create_audit_log(), member, %{password: valid_member_password()})

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
