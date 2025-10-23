defmodule HanaShirabe.Accounts do
  @moduledoc """
  账户相关上下文。
  """

  import Ecto.Query, warn: false
  alias HanaShirabe.Repo

  alias HanaShirabe.Accounts.{Member, MemberToken, MemberNotifier}

  ## 增删改查的查

  @doc """
  通过邮件返回成员。

  ## Examples

      iex> get_member_by_email("foo@example.com")
      %Member{}

      iex> get_member_by_email("unknown@example.com")
      nil

  """
  def get_member_by_email(email) when is_binary(email) do
    Repo.get_by(Member, email: email)
  end

  @doc """
  通过邮件以及密码返回成员。

  ## Examples

      iex> get_member_by_email_and_password("foo@example.com", "correct_password")
      %Member{}

      iex> get_member_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_member_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    member = Repo.get_by(Member, email: email)
    if Member.valid_password?(member, password), do: member
  end

  @doc """
  通过 ID 返回成员。

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id), do: Repo.get!(Member, id)

  ## 成员注册

  # 早晚有天改成邀请制度。
  @doc """
  注册一个新成员。

  ## Examples

      iex> register_member(%{field: value})
      {:ok, %Member{}}

      iex> register_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_member(attrs) do
    %Member{}
    |> Member.email_changeset(attrs)
    |> Repo.insert()
  end

  ## 设置

  @doc """
  Checks whether the member is in sudo mode.

  The member is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(member, minutes \\ -20)

  def sudo_mode?(%Member{authenticated_at: ts}, minutes) when is_struct(ts, NaiveDateTime) do
    NaiveDateTime.after?(ts, NaiveDateTime.utc_now() |> NaiveDateTime.add(minutes, :minute))
  end

  def sudo_mode?(_member, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the member email.

  See `HanaShirabe.Accounts.Member.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_member_email(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_email(member, attrs \\ %{}, opts \\ []) do
    Member.email_changeset(member, attrs, opts)
  end

  @doc """
  Updates the member email using the given token.

  If the token matches, the member email is updated and the token is deleted.
  """
  def update_member_email(member, token) do
    context = "change:#{member.email}"

    Repo.transact(fn ->
      with {:ok, query} <- MemberToken.verify_change_email_token_query(token, context),
           %MemberToken{sent_to: email} <- Repo.one(query),
           {:ok, member} <- Repo.update(Member.email_changeset(member, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(MemberToken, where: [member_id: ^member.id, context: ^context])) do
        {:ok, member}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the member password.

  See `HanaShirabe.Accounts.Member.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_member_password(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_password(member, attrs \\ %{}, opts \\ []) do
    Member.password_changeset(member, attrs, opts)
  end

  @doc """
  Updates the member password.

  Returns a tuple with the updated member, as well as a list of expired tokens.

  ## Examples

      iex> update_member_password(member, %{password: ...})
      {:ok, {%Member{}, [...]}}

      iex> update_member_password(member, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_member_password(member, attrs) do
    member
    |> Member.password_changeset(attrs)
    |> update_member_and_delete_all_tokens()
  end

  ## 会话

  @doc """
  生成会话的令牌。
  """
  def generate_member_session_token(member) do
    {token, member_token} = MemberToken.build_session_token(member)
    Repo.insert!(member_token)
    token
  end

  @doc """
  通过被认证的令牌返回成员。

  If the token is valid `{member, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_member_by_session_token(token) do
    {:ok, query} = MemberToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the member with the given magic link token.
  """
  def get_member_by_magic_link_token(token) do
    with {:ok, query} <- MemberToken.verify_magic_link_token_query(token),
         {member, _token} <- Repo.one(query) do
      member
    else
      _ -> nil
    end
  end

  @doc """
  Logs the member in by magic link.

  There are three cases to consider:

  1. The member has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The member has not confirmed their email and no password is set.
     In this case, the member gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The member has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_member_by_magic_link(token) do
    {:ok, query} = MemberToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%Member{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%Member{confirmed_at: nil} = member, _token} ->
        member
        |> Member.confirm_changeset()
        |> update_member_and_delete_all_tokens()

      {member, token} ->
        Repo.delete!(token)
        {:ok, {member, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given member.

  ## Examples

      iex> deliver_member_update_email_instructions(member, current_email, &url(~p"/members/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_member_update_email_instructions(%Member{} = member, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, member_token} = MemberToken.build_email_token(member, "change:#{current_email}")

    Repo.insert!(member_token)
    MemberNotifier.deliver_update_email_instructions(member, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given member.
  """
  def deliver_login_instructions(%Member{} = member, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, member_token} = MemberToken.build_email_token(member, "login")
    Repo.insert!(member_token)
    MemberNotifier.deliver_login_instructions(member, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_member_session_token(token) do
    Repo.delete_all(from(MemberToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## 令牌 helper

  defp update_member_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, member} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(MemberToken, member_id: member.id)

        Repo.delete_all(from(t in MemberToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {member, tokens_to_expire}}
      end
    end)
  end
end
