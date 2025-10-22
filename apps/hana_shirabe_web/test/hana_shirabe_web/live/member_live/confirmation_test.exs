defmodule HanaShirabeWeb.MemberLive.ConfirmationTest do
  use HanaShirabeWeb.ConnCase

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  alias HanaShirabe.Accounts

  setup do
    %{unconfirmed_member: unconfirmed_member_fixture(), confirmed_member: member_fixture()}
  end

  describe "Confirm member" do
    test "renders confirmation page for unconfirmed member", %{conn: conn, unconfirmed_member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/login/#{token}")
      assert html =~ "Confirm and stay logged in"
    end

    test "renders login page for confirmed member", %{conn: conn, confirmed_member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/login/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
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

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Member confirmed successfully"

      assert Accounts.get_member!(member.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/login/#{token}")
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Magic link is invalid or it has expired"
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

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Accounts.get_member!(member.id).confirmed_at == member.confirmed_at

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/login/#{token}")
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/login/invalid-token")
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
