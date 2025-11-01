defmodule HanaShirabeWeb.MemberLive.ConfirmationTest do
  use HanaShirabeWeb.ConnCase

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  alias HanaShirabe.Accounts

  use Gettext, backend: HanaShirabeWeb.Gettext

  setup do
    %{unconfirmed_member: unconfirmed_member_fixture(), confirmed_member: member_fixture()}
  end

  describe "确认成员" do
    # "renders confirmation page for unconfirmed member"
    test "对未经确认的成员渲染确认页面", %{conn: conn, unconfirmed_member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/login/#{token}")

      msg = dgettext("account", "Confirm and stay logged in")

      assert html =~ msg
    end

    # "renders login page for confirmed member"
    test "对确认的成员渲染登录页面", %{conn: conn, confirmed_member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/login/#{token}")
      cofirm_msg = dgettext("account", "Confirm my account")
      login_msg = dgettext("account", "Log in")

      refute html =~ cofirm_msg
      assert html =~ login_msg
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/login/#{token}")

      form = form(lv, "#confirmation_form", %{"member" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      msg = dgettext("account", "Member confirmed successfully.")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ msg

      assert Accounts.get_member!(member.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/login/#{token}")
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "Magic link is invalid or it has expired.")

      assert html =~ msg
    end

    test "logs confirmed member in without changing confirmed_at", %{
      conn: conn,
      confirmed_member: member
    } do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/login/#{token}")

      form = form(lv, "#login_form", %{"member" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      msg = dgettext("account", "Welcome back!")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ msg


      assert Accounts.get_member!(member.id).confirmed_at == member.confirmed_at

      # 用新的连接表示登出
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/login/#{token}")
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "Magic link is invalid or it has expired.")

      assert html =~ msg
    end

    test "非法链接抛出错误", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/login/invalid-token")
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "Magic link is invalid or it has expired.")

      assert html =~ msg
    end
  end
end
