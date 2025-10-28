defmodule HanaShirabe.AuditLog.Context do
  # 专门存储上下文

  @scope [:account, :member, :spectator, :moderator, :proposal, :site_generate_content]

  @doc """
  解释下这里的 scope 分别指什么

  - `:account`   => 账户相关，无论是否是管理员，只要在这个账号系统下，一视同仁
  - `:member`    => 普通成员相关
  - `spectator`  => 普通内容管理
  - `moderator`  => 普通成员管理
  - `proposal`  => 提案相关
  - `site_generate_content` => 站点生成内容（例如全站通知或是什么的）相关

  这里需要注意的是，因为 Phoenix 的 Scope 可能会存在多个键值，
  所以到这里需要按照操作本身以及语境做映射。

  不过更具体的区分可能需要根据业务作梳理。
  """
  def get_valid_scopes, do: @scope

  # 这是用 Cline 搓的
  # 后续需要根据业务进行调整以及补充
  @context_keys_required_within_scope_and_verb %{
    account: %{
      "sign_up" => [:account_id],
      "verify_email" => [:account_id],
      "update_email" => []
    },
    member: %{},
    spectator: %{},
    moderator: %{},
    proposal: %{},
    site_generate_content: %{}
  }

  @doc "通过范围以及动作返回所需到底上下文的键"
  def by_scope_and_verb(scope, verb)

  for {scope, map_within_scope} <- @context_keys_required_within_scope_and_verb,
      {verb, keys_map} <- map_within_scope do
    def by_scope_and_verb(unquote(scope), unquote(verb)), do: {:ok, unquote(keys_map)}
  end

  def by_scope_and_verb(_scope, _verb), do: {:error, :not_found}
end

defmodule HanaShirabe.AuditLog do
  @moduledoc """
  类似于「岁月史书」的功能。

  ### 格式说明

  主体（用户或系统）在 `insert_at` 时执行了有关 `scope` 领域的
  `verb` 行动，其上下文为 `context` 。

  上下文主要是被操作的对象（比方说管理员动用权限删除推文或封禁用户）
  的类别以及 ID 或者是相关的数据，在操作时需要被检查或验证。
  """
  use Ecto.Schema

  import Ecto.Changeset
  alias HanaShirabe.Repo
  alias HanaShirabe.AuditLog.Context

  schema "audit_logs" do
    field :scope, {:array, Ecto.Enum}, values: Context.get_valid_scopes()

    field :verb, :string
    field :user_agent, :string
    field :ip_addr, HanaShirabe.EctoIP
    field :context, :map, default: %{}
    belongs_to :member, HanaShirabe.Accounts.Member

    timestamps(updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:verb, :scope, :ip_addr, :user_agent, :context])
    |> validate_required([:verb, :scope, :ip_addr, :user_agent])
  end

  @doc """
  插入一条日志。
  """
  def audit!(audit_context, scope, verb, context) do
    Repo.insert!(build!(audit_context, scope, verb, context))
  end

  @doc """
  在操作中添加 Audit 日志。

  其最后一个参数可以是函数或上下文本身。

  前者需要提供一个能够从 Audit 以及数据库的返回结果对数据进行处理的函数。
  """
  def multi(multi, audit_context, scope, verb, callback_or_context)

  # 需要来自 Ecto 的查询结果
  def multi(multi, audit_context, scope, verb, callback) when is_function(callback, 2) do
    Ecto.Multi.run(multi, :audit, fn repo, res ->
      log = build!(callback.(audit_context, res), scope, verb, %{})
      {:ok, repo.insert!(log)}
    end)
  end

  def multi(multi, audit_context, scope, verb, context) when is_map(context) do
    Ecto.Multi.insert(multi, :audit, fn _ ->
      build!(audit_context, scope, verb, context)
    end)
  end

  # 构造

  # TODO: 确定 scope 的具体类型
  defp build!(%__MODULE__{} = audit_context, scope, verb, context)
       when is_binary(verb) and is_map(context) do
    # 一般地讲，audit_context 已经包括了用户相关的信息
    %{
      audit_context
      | scope: scope,
        verb: verb,
        context: Map.merge(audit_context.context, context)
    }

    # TODO: validate
  end

  # TODO：
  # 创建一个从 Phoenix 的 Scope 构造 AuditLog 的函数
  # 具体地说，是决定 AuditLog 中的 scope 字段
  # 因为那决定着 context 里边的键到底有哪些
end
