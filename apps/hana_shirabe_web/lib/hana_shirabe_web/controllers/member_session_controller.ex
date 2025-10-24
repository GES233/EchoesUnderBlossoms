defmodule HanaShirabeWeb.MemberSessionController do
  # 这个… 等我把别的文档翻译好了再回来看
  # 至少可以确定的是，这是一个直接和 Router 交互的 Controller
  # TODO: 翻译 flash 的消息

  use HanaShirabeWeb, :controller

  alias HanaShirabe.Accounts
  alias HanaShirabeWeb.MemberAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "Member confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # 经由链接的登录
  defp create(conn, %{"member" => %{"token" => token} = member_params}, info) do
    case Accounts.login_member_by_magic_link(token) do
      {:ok, {member, tokens_to_disconnect}} ->
        MemberAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> MemberAuth.log_in_member(member, member_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/login")
    end
  end

  # 经由邮件与密码的登录
  defp create(conn, %{"member" => member_params}, info) do
    %{"email" => email, "password" => password} = member_params

    if member = Accounts.get_member_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> MemberAuth.log_in_member(member, member_params)
    else
      # 为防止邮件地址枚举攻击
      # （for mail <- 1000000000...2999999999, mail |> Integer.to_string() <> "@qq.com", do: blabla）
      # 不要透露邮件地址是否已注册。
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def update_password(conn, %{"member" => member_params} = params) do
    member = conn.assigns.current_scope.member
    true = Accounts.sudo_mode?(member)
    {:ok, {_member, expired_tokens}} = Accounts.update_member_password(member, member_params)

    # 断开所有使用旧会话的现有 LiveViews
    MemberAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:member_return_to, ~p"/me/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> MemberAuth.log_out_member()
  end
end
