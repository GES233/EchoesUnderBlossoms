defmodule HanaShirabe.AuditLog do
  @moduledoc """
  类似于「岁月史书」的功能。
  """
  use Ecto.Schema

  import Ecto.Changeset
  alias HanaShirabe.Repo

  schema "audit_log" do
    field :scope, Ecto.Enum, values: [:account, :member, :spectator, :moderator, :proposal]
    field :verb, :string
    field :user_agent, :string
    field :ip_addr, HanaShirabe.EctoIP
    field :context, :map, default: %{}
    # TODO: belongs to user.

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
