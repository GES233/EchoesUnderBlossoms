defmodule HanaShirabeWeb.MemberSessionController do
  use HanaShirabeWeb, :controller

  alias HanaShirabe.Accounts
  alias HanaShirabeWeb.MemberAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "Member confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
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

  # email + password login
  defp create(conn, %{"member" => member_params}, info) do
    %{"email" => email, "password" => password} = member_params

    if member = Accounts.get_member_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> MemberAuth.log_in_member(member, member_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
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

    # disconnect all existing LiveViews with old sessions
    MemberAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:member_return_to, ~p"/members/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> MemberAuth.log_out_member()
  end
end
