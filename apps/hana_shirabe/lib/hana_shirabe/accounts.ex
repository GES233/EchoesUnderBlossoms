defmodule HanaShirabe.Accounts do
  @moduledoc """
  账户相关上下文。
  """

  require Logger

  import Ecto.Query, warn: false
  alias HanaShirabe.{Repo, AuditLog}

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

  如果用户不存在将会抛出 `Ecto.NoResultsError` 错误。

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

      iex> register_member(%AuditLog{}, %{field: value})
      {:ok, %Member{}}

      iex> register_member(%AuditLog{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_member(audit_log, attrs) do
    member_changeset =
      %Member{}
      |> Member.email_changeset(attrs)

    # 改成针对两个数据库的检查
    Ecto.Multi.new()
    # 这里的 :name 选项更像是一个标签，用于区分 Ecto.Multi 操作中的不同步骤
    |> Ecto.Multi.insert(:member, member_changeset)
    |> AuditLog.multi(
      audit_log,
      :account,
      "member.sign_up",
      fn audit_log, %{member: member} ->
        # 没有 {:ok, ...} 主要留意
        # 这里只考虑成功是一旦是 {:error, _} 就不会调用这个函数了
        %{
          audit_log
          | context: %{"account_id" => member.id, "email" => member.email},
            member: member
        }

        # 另外一点是注册比较特殊，上下文没有用户，所以需要把用户再注入进去
      end
    )
    |> Repo.transact()
    |> case do
      {:ok, %{member: member}} -> {:ok, member}
      {:error, :member, changeset, _} -> {:error, changeset}
    end
  end

  ## 设置

  @doc """
  检查用户是否在 sudo 模式。

  The member is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(member, minutes \\ -20)

  def sudo_mode?(%Member{authenticated_at: ts}, minutes) when is_struct(ts, NaiveDateTime) do
    NaiveDateTime.after?(ts, NaiveDateTime.utc_now() |> NaiveDateTime.add(minutes, :minute))
  end

  def sudo_mode?(_member, _minutes), do: false

  @doc """
  更换成员邮件时返回变化表（`%Ecto.Changeset{}`）。

  可查看 `HanaShirabe.Accounts.Member.email_changeset/3` 以获得支持选项的列表。

  ## Examples

      iex> change_member_email(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_email(member, attrs \\ %{}, opts \\ []) do
    Member.email_changeset(member, attrs, opts)
  end

  @doc """
  使用给定的令牌更新成员邮件。

  一旦令牌匹配，成员邮件将会被更新并且令牌被删除。
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
  返回修改成员密码时的变化表（以 `%Ecto.Changeset{}` 结构体为主）。

  参见 `HanaShirabe.Accounts.Member.password_changeset/3` 可以查看支持的选项。

  ## Examples

      iex> change_member_password(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_password(member, attrs \\ %{}, opts \\ []) do
    Member.password_changeset(member, attrs, opts)
  end

  @doc """
  更新成员的密码。

  返回一个含有更新的成员以及过期令牌列表的元组。

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

  一旦令牌合法，将会返回 `{member, token_inserted_at}` ，否则返回 `nil` 。
  """
  def get_member_by_session_token(token) do
    {:ok, query} = MemberToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  根据 magic link 的令牌返回成员。
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
  通过 magic link 返回成员，

  需要注意的是三个用例：

  1. 成员已经确认了邮件。他们登录进来并且 magic link 过期。

  2. 成员已经确认了他们的邮件但是没有设置密码。
     早这个案例中，成员确认了、登录了，而且所有的令牌——
     包括会话——都过期了。在这种情况，没有任何现存令牌，因此我们为最佳安全实践
     删除了所有这些。

  3. 成员没有确认邮件，但是已经设置密码了。
     这默认情况下不可能发生，但是可能因为安全的 pitfalls 发生。
     参见 "mix help phx.gen.auth" 中的 "Mixing magic link and password registration"（） 一节。
  """
  def login_member_by_magic_link(token) do
    {:ok, query} = MemberToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # 预防会话固定攻击，通过不允许未确认用户使用密码的 magic link 来实现
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
  将更新邮件指令发送给指定的成员。

  ## Examples

      iex> deliver_member_update_email_instructions(member, current_email, &url(~p"/me/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_member_update_email_instructions(
        %Member{} = member,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, member_token} =
      MemberToken.build_email_token(member, "change:#{current_email}")

    Repo.insert!(member_token)
    MemberNotifier.deliver_update_email_instructions(member, update_email_url_fun.(encoded_token))
  end

  @doc """
  将 magic link 登录指令发送给指定的成员。
  """
  def deliver_login_instructions(%Member{} = member, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, member_token} = MemberToken.build_email_token(member, "login")
    Repo.insert!(member_token)
    MemberNotifier.deliver_login_instructions(member, magic_link_url_fun.(encoded_token))
  end

  @doc """
  删除指定上下文的已签名令牌。
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

        Repo.delete_all(
          from(t in MemberToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id))
        )

        {:ok, {member, tokens_to_expire}}
      end
    end)
  end

  ## 与 AuditLog 的封装

  def authenticate_and_log_via_password(audit_context, email, password) do
    authenticate_and_log(
      audit_context,
      get_member_by_email_and_password(email, password),
      {:email, email}
    )
  end

  def authenticate_and_log_via_magic_link_token(audit_context, token) do
    authenticate_and_log(audit_context, get_member_by_magic_link_token(token), :magic_link)
  end

  defp authenticate_and_log(audit_context, member_from_database, maybe_identifier) do
    case {member_from_database, audit_context.member} do
      {member_from_re_authenticate, _member_from_audit} = {%Member{}, %Member{}} ->
        AuditLog.audit!(audit_context, :account, "member.login.re_authenticate", %{
          "account_id" => member_from_re_authenticate.id
        })

        member_from_re_authenticate

      {nil, _member_from_audit} = {nil, %Member{}} ->
        # 这种情况得考虑用户把密码忘了，或者是操作的不是本人

        nil

      {member, nil} = {%Member{}, nil} ->
        verb =
          case maybe_identifier do
            {:email, _} -> "member.login.via_email"
            :magic_link -> "member.login.via_link"
          end

        AuditLog.audit!(audit_context, :account, verb, %{
          "account_id" => member.id
        })

        member

      {nil, nil} ->
        attempt_target =
          case maybe_identifier do
            {:email, email} -> get_member_by_email(email) || %{id: nil}
            _ -> %{id: nil}
          end

        AuditLog.audit!(audit_context, :account, "member.login.via_email_attempt", %{
          "maybe_target_account_id" => attempt_target.id
        })

        nil
    end
  end

  def logout_member_in_purpose_with_log(audit_context, token) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:fetch_id_from_token, fn repo, _changes ->
      case repo.get_by(MemberToken, token: token) do
        nil ->
          {:error, :token_not_found}

        member_token ->
          {:ok, member_token}
      end
    end)
    |> AuditLog.multi(
      audit_context,
      :account,
      "member.logout.in_purpose",
      fn audit_log, %{fetch_id_from_token: member_token} ->
        context = %{"account_id" => member_token.member_id}
        # 还需要注入，因为不确定清除 member 和 执行该函数哪个在前
        %{audit_log | context: context, member: member_token.member}
      end
    )
    |> Ecto.Multi.delete_all(
      :delete_token,
      from(MemberToken, where: [token: ^token, context: "session"])
    )
    |> Repo.transact()
    |> case do
      {:ok, _} ->
        :ok

      {:error, :token_not_found, _, _} ->
        :ok

      {:error, failed_op, reason, _changes} ->
        Logger.error("Failed to log out and log: #{failed_op}, #{inspect(reason)}")

        :ok
    end
  end

  def update_member_password_with_log(audit_context, member, attrs) do
    case update_member_password(member, attrs) do
      {:ok, {member = %Member{id: id}, tokens}} ->
        AuditLog.audit!(audit_context, :account, "member.update_password", %{"account_id" => id})

        {:ok, {member, tokens}}

      err_with_changeset ->
        err_with_changeset
    end
  end
end
