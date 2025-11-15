defmodule HanaShirabe.Accounts.Scope do
  @moduledoc """
  定义整个应用程序中调用者的作用域。

  `HanaShirabe.Accounts.Scope` 允许公共接口获取调用者信息，
  例如调用是否由终端用户发起，若为用户调用则可识别具体用户身份。
  此外，此范围可承载“超级用户”等特权字段，用于授权验证或
  确保特定代码路径仅限于指定范围访问。

  该功能在调用方订阅接口或执行特定操作时，既适用于日志记录，
  也适用于 pubsub 订阅与广播的范围限定。

  欢迎根据应用程序不断增长的需求扩展此结构体的字段。

  ## TODO:

  添加 prefer_locale audit_context 。
  """

  # 建议参考文档：
  # https://hexdocs.pm/phoenix/scopes.html

  alias HanaShirabe.Accounts.Member
  alias HanaShirabe.AuditLog

  defstruct [member: nil, audit_context: nil, prefer_locale: nil]

  @doc """
  从给定用户返回作用域。

  如果没有成员那么返回 nil 。
  """
  def for_member(%Member{} = member) do
    %__MODULE__{
      member: member,
      prefer_locale: member.prefer_locale
    }
  end

  def for_member(nil), do: nil

  @doc """
  根据事物日志返回作用域。
  """
  def for_audit_log(%AuditLog{} = audit_context) do
    %__MODULE__{
      member: audit_context.member,
      audit_context: audit_context,
      prefer_locale: if(audit_context.member, do: audit_context.member.prefer_locale, else: nil)
    }
  end

  def for_audit_log(nil), do: nil

  def for_audit_log(%AuditLog{} = audit_context, %Member{} = member) do
    %__MODULE__{
      member: member,
      audit_context: audit_context,
      prefer_locale: member.prefer_locale
    }
  end

  def for_audit_log(%AuditLog{} = audit_context, nil) do
    %__MODULE__{
      audit_context: audit_context
    }
  end

  # def for(opts) when is_list(opts) do end
end
