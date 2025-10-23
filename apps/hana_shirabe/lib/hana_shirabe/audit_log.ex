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

  schema "audit_log" do
    # 解释下这里的 scope 分别指什么
    # account   => 账户相关，无论是否是管理员，只要在这个账号系统下，一视同仁
    # member    => 普通成员相关
    # spectator => 普通内容管理
    # moderator => 普通成员管理
    # proposal  => 提案相关
    # 这里需要注意的是，因为 Phoenix 的 Scope 可能会存在多个键值
    # 所以到这里需要按照操作本身以及语境做映射
    # 不过更具体的区分可能需要根据业务作梳理
    field :scope, Ecto.Enum, values: [:account, :member, :spectator, :moderator, :proposal, :site_generate_content]
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
  def multi(multi, audit_context, scope, verb, function) when is_function(function, 2) do
    Ecto.Multi.run(multi, :audit, fn repo, res ->
      log = build!(function.(audit_context, res), scope, verb, %{})
      {:ok, repo.insert!(log)}
    end)
  end

  def multi(multi, audit_context, scope, verb, context) when is_map(context) do
    Ecto.Multi.insert(multi, :audit, fn _ ->
      build!(audit_context, scope, verb, context)
    end)
  end

  # 构造

  defp build!(%__MODULE__{} = audit_context, scope, verb, context)
       when is_atom(scope) and is_binary(verb) and is_map(context) do
    # 一般地讲，audit_context 已经包括了用户相关的信息
    %{
      audit_context
      | scope: scope,
        verb: verb,
        context: Map.merge(audit_context.context, context)
    }

    # TODO: validate
  end
end
