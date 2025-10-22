defmodule HanaShirabeWeb.RequestContext do
  @moduledoc """
  ...
  """

  alias HanaShirabe.AuditLog

  @request_context_key :audit_log

  # def get_audit_context(conn_or_socket)

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
        conn_or_socket
        |> Phoenix.Component.assign(%{@request_context_key => fetch_audit_log(conn_or_socket, opts)})
    end
  end

  defp fetch_audit_log(_conn_or_socket, _opts)

  defp fetch_audit_log(%Plug.Conn{} = conn, _opts) do
    ip = conn.remote_ip
    user_agent = case List.keyfind(conn.req_headers, "user-agent", 0) do
      {_, value} -> value
      _ -> nil
    end

    construct_audit_log(nil, ip, user_agent)
  end

  defp fetch_audit_log(%Phoenix.LiveView.Socket{} = socket, _opts) do
    %{address: ip} = Phoenix.LiveView.get_connect_info(socket, :peer_data)
    user_agent = Phoenix.LiveView.get_connect_info(socket, :user_agent)

    construct_audit_log(nil, ip, user_agent)
  end

  defp construct_audit_log(_user, ip, user_agent) do
    struct!(
      AuditLog,
      %{
        # user: nil,
        ip_addr: ip,
        user_agent: user_agent
      }
    )
  end
end
