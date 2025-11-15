defmodule HanaShirabeWeb.MountConnectInfo do
  import Phoenix.{LiveView, Component}

  def on_mount(:mount, _params, _session, socket) do
    %{address: ip} = get_connect_info(socket, :peer_data)
    user_agent = get_connect_info(socket, :user_agent)

    # 将信息存储到 assigns 中，供后续使用
    socket =
      socket
      |> assign(:ip_addr, ip)
      |> assign(:user_agent, user_agent)

    {:cont, socket}
  end
end
