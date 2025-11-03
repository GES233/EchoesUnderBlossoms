defmodule HanaShirabeWeb.MemberSessionController do
  use HanaShirabeWeb, :controller

  alias HanaShirabe.Accounts
  alias HanaShirabeWeb.MemberAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    confirm_success_msg = dgettext("account", "Member confirmed successfully.")

    create(conn, params, confirm_success_msg)
  end

  def create(conn, params) do
    login_success_msg = dgettext("account", "Welcome back!")

    create(conn, params, login_success_msg)
  end

  # 经由链接的登录
  defp create(conn, %{"member" => %{"token" => token} = member_params}, info) do
    case Accounts.log_in_by_magic_link_and_log(conn.assigns[:audit_log], token) do
      {:ok, {member, tokens_to_disconnect}} ->
        # 业务逻辑（包括日志）已在 Accounts 中完成
        MemberAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> MemberAuth.log_in_member(member, member_params)

      {:error, _reason} ->
        # Accounts 模块已经记录了失败日志
        maybe_link_unusable_msg = dgettext("account", "The link is invalid or it has expired.")

        conn
        |> put_flash(:error, maybe_link_unusable_msg)
        |> redirect(to: ~p"/login")
    end
  end

  # 经由邮件与密码的登录
  defp create(conn, %{"member" => member_params}, info) do
    audit_context = conn.assigns[:audit_log]

    %{"email" => email, "password" => password} = member_params

    if member = Accounts.authenticate_and_log_via_password(audit_context, email, password) do
      conn
      |> put_flash(:info, info)
      |> MemberAuth.log_in_member(member, member_params)
    else
      # 为防止邮件地址枚举攻击
      # （for mail <- 1000000000...2999999999, mail |> Integer.to_string() <> "@qq.com", do: blabla）
      # 不要透露邮件地址是否已注册。
      err_msg = dgettext("account", "Invalid email or password")

      conn
      |> put_flash(:error, err_msg)
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def update_password(conn, %{"member" => member_params} = params) do
    member = conn.assigns.current_scope.member
    true = Accounts.sudo_mode?(member)

    {:ok, {_member, expired_tokens}} =
      Accounts.update_member_password_with_log(conn.assigns[:audit_log], member, member_params)

    update_pswd_msg = dgettext("account", "Password updated successfully.")

    # 断开所有使用旧会话的现有 LiveViews
    MemberAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:member_return_to, ~p"/me/settings")
    |> create(params, update_pswd_msg)
  end

  def delete(conn, _params) do
    log_out_msg = dgettext("account", "Logged out successfully.")

    conn
    |> put_flash(:info, log_out_msg)
    |> MemberAuth.log_out_member()
  end
end
