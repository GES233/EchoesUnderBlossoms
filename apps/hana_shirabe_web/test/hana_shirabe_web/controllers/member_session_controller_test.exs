defmodule HanaShirabeWeb.MemberSessionControllerTest do
  use HanaShirabeWeb.ConnCase

  import HanaShirabe.AccountsFixtures
  alias HanaShirabe.Accounts

  use Gettext, backend: HanaShirabeWeb.Gettext

  setup do
    %{unconfirmed_member: unconfirmed_member_fixture(), member: member_fixture()}
  end

  describe "POST /login - 通过邮件以及密码" do
    test "成员登录", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        post(conn, ~p"/login", %{
          "member" => %{"email" => member.email, "password" => valid_member_password()}
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/me/sensitive-settings"
      assert response =~ ~p"/logout"
    end

    test "附带了记住我的成员登录", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        post(conn, ~p"/login", %{
          "member" => %{
            "email" => member.email,
            "password" => valid_member_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_hana_shirabe_web_member_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "附带跳转地址的成员登录", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        conn
        |> init_test_session(member_return_to: "/foo/bar")
        |> post(~p"/login", %{
          "member" => %{
            "email" => member.email,
            "password" => valid_member_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"

      welcomeback = dgettext("account", "Welcome back!")
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ welcomeback
    end

    test "凭证不正确会重定向至登录界面", %{conn: conn, member: member} do
      conn =
        post(conn, ~p"/login?mode=password", %{
          "member" => %{"email" => member.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               dgettext("account", "Invalid email or password")

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "POST /login - 通过链接" do
    test "登录", %{conn: conn, member: member} do
      {token, _hashed_token} = generate_member_magic_link_token(member)

      conn =
        post(conn, ~p"/login", %{
          "member" => %{"token" => token}
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/me/sensitive-settings"
      assert response =~ ~p"/logout"
    end

    test "确认成员账号", %{conn: conn, unconfirmed_member: member} do
      {token, _hashed_token} = generate_member_magic_link_token(member)
      refute member.confirmed_at

      conn =
        post(conn, ~p"/login", %{
          "member" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      err_msg = dgettext("account", "Member confirmed successfully.")
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ err_msg

      assert Accounts.get_member!(member.id).confirmed_at

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/me/sensitive-settings"
      assert response =~ ~p"/logout"
    end

    test "链接有问题重定向至登录", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{
          "member" => %{"token" => "invalid"}
        })

      err_msg = dgettext("account", "The link is invalid or it has expired.")
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == err_msg

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "DELETE /logout" do
    test "成员登出", %{conn: conn, member: member} do
      conn = conn |> log_in_member(member) |> delete(~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :member_token)
      msg = dgettext("account", "Logged out successfully.")
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ msg
    end

    test "未登录也可登出", %{conn: conn} do
      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :member_token)
      msg = dgettext("account", "Logged out successfully.")
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ msg
    end
  end
end
