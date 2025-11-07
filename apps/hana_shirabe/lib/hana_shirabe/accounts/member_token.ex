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

  def get_expire(), do: {15, "minutes"}

  schema "members_tokens" do
    field :token, :binary
    field :code, :string, virtual: true
    field :context, :string
    field :sent_to, :string
    field :authenticated_at, :naive_datetime
    belongs_to :member, HanaShirabe.Accounts.Member

    timestamps(updated_at: false)
  end

  @doc "因为其他模块会用到所以直接写个函数调过去。"
  def get_session_validity_in_days, do: @session_validity_in_days

  @doc """
  生成一个将会保存在类似于会话或 cookie 的 signed place 的令牌。
  当被签名验证时，这些令牌不需要被散列处理。

  我们将会话令牌保存在数据库里（哪怕 Phoenix 以及有了基于会话的
  cookie）的原因，是因为 Phoenix 默认提供的会话 cookie
  并不是持久化存储的，它们只是被签名和可能被加密的。
  这意味着它们是无限期有效的，除非你更改签名/加密盐值。

  因此，存储它们允许单独的成员会话被过期。
  令牌系统也可以被扩展以存储额外的数据，比如用于登录的设备。
  然后，您可以使用此信息在 UI 中显示所有有效的会话和设备，
  并允许用户明确地使他们认为无效的任何会话过期。
  """
  def build_session_token(member) do
    token = :crypto.strong_rand_bytes(@rand_size)
    dt = member.authenticated_at || NaiveDateTime.utc_now(:second)

    {token,
     %MemberToken{token: token, context: "session", member_id: member.id, authenticated_at: dt}}
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
  构建一个令牌且将其的哈希值发送到成员的电子邮件。

  未经散列处理的令牌被发送到成员的电子邮件，而散列处理的部分则存储在数据库中。
  原始令牌无法被重建，这意味着任何对数据库有只读访问权限的人都无法直接在应用程序中使用该令牌来获得访问权限。
  此外，如果成员在系统中更改了他们的电子邮件，则发送到先前电子邮件的令牌将不再有效。

  用户可以轻易的适配现有代码来提供其他类型的传递方法，例如通过电话号码。
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
  检查令牌是否合法并返回其底层查询。

  一旦找到，查询将返回一个形式为 `{member, token}` 的元组。

  给定的令牌如果与数据库中其散列对应项匹配则有效。
  此函数还检查令牌是否在15分钟内被使用。
  魔法链接令牌的上下文始终是 "login" 。
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
  用于验证码注册的辅助函数。

  返回所有用户
  """
  def verify_magic_code_via_email_query(email) do
    query =
      from token in by_context_query("login"),
        join: member in assoc(token, :member),
        where: token.inserted_at > ago(^@magic_link_validity_in_minutes, "minute"),
        where: token.sent_to == member.email,
        where: token.sent_to == ^email,
        select: {member, token},
        order_by: [desc: token.inserted_at],
        limit: 10

    query
  end

  @doc """
  检查令牌是否合法并返回其底层查询。

  一旦通过令牌找到，查询将返回 member_token 。

  这是用来验证更改成员电子邮件的请求。
  给定的令牌如果与数据库中其散列对应项匹配则有效。
  并且如果它没有过期（在 @change_email_validity_in_days 之后）。
  上下文必须始终以 "change:" 开头。
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

  # 这个功能先不留了
  # 但还是注释一下
  # def verify_change_email_code_query(code, "change:" <> _ = context) do
  #   query =
  #     from token in by_code_and_context_query(context),
  #       where: token.inserted_at > ago(@change_email_validity_in_days, "day")

  #   {:ok, query}
  # end

  defp by_token_and_context_query(token, context) do
    from MemberToken, where: [token: ^token, context: ^context]
  end

  defp by_context_query(context) do
    from MemberToken, where: [context: ^context]
  end
end
