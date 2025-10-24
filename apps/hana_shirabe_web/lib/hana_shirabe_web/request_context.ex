defmodule HanaShirabeWeb.RequestContext do
  @moduledoc """
  将 `%AuditLog{}` 挂载在用户的请求上下文中。

  （可能后面会挂别的，但是目前只有这个）
  """

  alias HanaShirabe.AuditLog

  @request_context_key :audit_log

  # TODO: 考虑实现 on_mount 以适配 LiveView
  # def on_mount(:mount_audit_log, _params, _session, socket) do
  #   {:cont, put_audit_context(socket, session)}
  # end

  # 因为是照抄 https://github.com/dashbitco/bytepack_archive
  # 所以不知道现在 Plug 还能跑
  @doc """
  从用户的请求构造获取 %AuditLog{} 的上下文。
  """
  def put_audit_context(conn_or_socket, opts \\ []) do
    case conn_or_socket do
      %Plug.Conn{} ->
        conn_or_socket
        |> Plug.Conn.assign(@request_context_key, fetch_audit_log(conn_or_socket, opts))

      %Phoenix.LiveView.Socket{} ->
        # 主要在 MountHelpers 使用
        conn_or_socket
        |> Phoenix.Component.assign(%{
          @request_context_key => fetch_audit_log(conn_or_socket, opts)
        })
    end
  end

  defp fetch_audit_log(_conn_or_socket, _opts)

  defp fetch_audit_log(%Plug.Conn{} = conn, _opts) do
    ip = conn.remote_ip

    user_agent =
      case List.keyfind(conn.req_headers, "user-agent", 0) do
        {_, value} -> value
        _ -> nil
      end

    member =
      case conn.assigns[:current_scope] do
        nil -> nil
        %{member: member} -> member
      end

    construct_audit_log(member, ip, user_agent)
  end

  defp fetch_audit_log(%Phoenix.LiveView.Socket{} = socket, _opts) do
    %{address: ip} = Phoenix.LiveView.get_connect_info(socket, :peer_data)
    user_agent = Phoenix.LiveView.get_connect_info(socket, :user_agent)

    # 从 Scope 中返回用户
    member =
      case socket.assigns[:current_scope] do
        nil -> nil
        %{member: member} -> member
      end

    construct_audit_log(member, ip, user_agent)
  end

  defp construct_audit_log(member, ip, user_agent) do
    struct!(
      AuditLog,
      %{
        member_id: if(is_struct(member, HanaShirabe.Accounts.Member), do: member.id, else: nil),
        ip_addr: ip,
        user_agent: user_agent
      }
    )
  end
end
