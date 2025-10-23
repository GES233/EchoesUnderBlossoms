defmodule HanaShirabe.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `HanaShirabe.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """
  # 建议参考文档：
  # https://hexdocs.pm/phoenix/scopes.html

  alias HanaShirabe.Accounts.Member

  defstruct member: nil

  @doc """
  Creates a scope for the given member.

  Returns nil if no member is given.
  """
  def for_member(%Member{} = member) do
    %__MODULE__{member: member}
  end

  def for_member(nil), do: nil

  # def for(opts) when is_list(opts) do end
end
