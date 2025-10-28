defmodule HanaShirabe.Accounts.MemberToken do
  use Ecto.Schema
  import Ecto.Query
  alias HanaShirabe.Accounts.MemberToken

  @hash_algorithm :sha256
  @rand_size 32

  # 令登录链接的令牌快速过期很重要，
  # 因为其他人有可能看到邮件。
  @magic_link_validity_in_minutes 15
  @change_email_validity_in_days 7
  @session_validity_in_days 14

  schema "members_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :authenticated_at, :naive_datetime
    belongs_to :member, HanaShirabe.Accounts.Member

    timestamps(updated_at: false)
  end

  @doc "因为其他模块会用到所以直接写个函数调过去。"
  # coveralls-ignore-next-line
  def get_session_validity_in_days, do: @session_validity_in_days

  @doc """
  生成一个将会保存在类似于会话或 cookie 的 signed place 的令牌。
  当被签名验证时，这些令牌不需要被散列处理。

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual member
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(member) do
    token = :crypto.strong_rand_bytes(@rand_size)
    dt = member.authenticated_at || NaiveDateTime.utc_now(:second)
    {token, %MemberToken{token: token, context: "session", member_id: member.id, authenticated_at: dt}}
  end

  @doc """
  检查令牌是否合法并且通过查询返回。

  如果令牌合法，查询将会返回成员，以及令牌的建立时间。

  一旦数据库有匹配结果并且令牌没有过期（在 @session_validity_in_days 后），令牌合法。
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: member in assoc(token, :member),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: {%{member | authenticated_at: token.authenticated_at}, token.inserted_at}

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the member's email.

  The non-hashed token is sent to the member email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the member changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(member, context) do
    build_hashed_token(member, context, member.email)
  end

  defp build_hashed_token(member, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %MemberToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       member_id: member.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  If found, the query returns a tuple of the form `{member, token}`.

  The given token is valid if it matches its hashed counterpart in the
  database. This function also checks if the token is being used within
  15 minutes. The context of a magic link token is always "login".
  """
  def verify_magic_link_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, "login"),
            join: member in assoc(token, :member),
            where: token.inserted_at > ago(^@magic_link_validity_in_minutes, "minute"),
            where: token.sent_to == member.email,
            select: {member, token}

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the member_token found by the token, if any.

  This is used to validate requests to change the member
  email.
  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  defp by_token_and_context_query(token, context) do
    from MemberToken, where: [token: ^token, context: ^context]
  end
end
