defmodule HanaShirabeWeb.MemberLive.SettingsTest do
  use HanaShirabeWeb.ConnCase

  alias HanaShirabe.Accounts
  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  use Gettext, backend: HanaShirabeWeb.Gettext

  describe "Settings page" do
    test "渲染设置页面", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/me/settings")

      assert html =~ dgettext("account", "Change Email")
      assert html =~ dgettext("account", "Save Password")
    end

    test "成员未登录会被重定向", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/me/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      %{"error" => message} = flash
      assert message =~ dgettext("account", "You must log in to access this page.")
    end

    test "用户未验证（ sudo 模式）会被重定向", %{conn: conn} do
      {:ok, conn} =
        conn
        |> log_in_member(member_fixture(),
          token_authenticated_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/me/settings")
        |> follow_redirect(conn, ~p"/login")

      assert conn.resp_body =~ dgettext("account", "You must re-authenticate to access this page.")
    end
  end

  describe "更新邮件表单" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end

    test "更新成员邮件", %{conn: conn, member: member} do
      new_email = unique_member_email()

      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      result =
        lv
        |> form("#email_form", %{
          "member" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ dgettext("account", "A link to confirm your email")
      assert Accounts.get_member_by_email(member.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "member" => %{"email" => "with spaces"}
        })

      assert result =~ dgettext("account", "Change Email")
      assert result =~ dgettext("account", "must have the @ sign and no spaces")
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, member: member} do
      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      result =
        lv
        |> form("#email_form", %{
          "member" => %{"email" => member.email}
        })
        |> render_submit()

      assert result =~ dgettext("account", "Change Email")
      assert result =~ dgettext("account", "did not change")
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end

    test "updates the member password", %{conn: conn, member: member} do
      new_password = valid_member_password()

      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      form =
        form(lv, "#password_form", %{
          "member" => %{
            "email" => member.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/me/settings"

      assert get_session(new_password_conn, :member_token) != get_session(conn, :member_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               dgettext("account", "Password updated successfully")

      assert Accounts.get_member_by_email_and_password(member.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "member" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ dgettext("account", "Save Password")
      assert result =~ dgettext("account", "should be at least 12 character(s)")
      assert result =~ dgettext("account", "does not match password")
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/settings")

      result =
        lv
        |> form("#password_form", %{
          "member" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ dgettext("account", "Save Password")
      assert result =~ dgettext("account", "should be at least 12 character(s)")
      assert result =~ dgettext("account", "does not match password")
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      member = member_fixture()
      email = unique_member_email()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(%{member | email: email}, member.email, url)
        end)

      %{conn: log_in_member(conn, member), token: token, email: email, member: member}
    end

    test "updates the member email once", %{conn: conn, member: member, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/settings"
      assert %{"info" => message} = flash
      assert message == dgettext("account", "Email changed successfully.")
      refute Accounts.get_member_by_email(member.email)
      assert Accounts.get_member_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/settings"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "Email change link is invalid or it has expired.")
    end

    test "does not update email with invalid token", %{conn: conn, member: member} do
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/settings"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "Email change link is invalid or it has expired.")
      assert Accounts.get_member_by_email(member.email)
    end

    test "redirects if member is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "You must log in to access this page.")
    end
  end
end
