defmodule HanaShirabeWeb.MemberLive.SensitiveSettingsTest do
  use HanaShirabeWeb.ConnCase

  alias HanaShirabe.Accounts
  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  use Gettext, backend: HanaShirabeWeb.Gettext

  describe "成员设置页面" do
    test "渲染设置页面", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/me/sensitive-settings")

      assert html =~ dgettext("account", "Change Email")
      assert html =~ dgettext("account", "Save Password")
    end

    test "成员未登录会被重定向", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/me/sensitive-settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      %{"error" => message} = flash
      assert message =~ dgettext("account", "You must log in to access this page.")
    end

    test "用户未验证（不在 sudo 模式）会被重定向", %{conn: conn} do
      {:ok, conn} =
        conn
        |> log_in_member(member_fixture(),
          token_authenticated_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/me/sensitive-settings")
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "You must re-authenticate to access this page.")
      assert conn.resp_body =~ msg
    end
  end

  describe "更新邮件表单" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end

    test "更新成员邮件", %{conn: conn, member: member} do
      new_email = unique_member_email()

      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

      result =
        lv
        |> form("#email_form", %{
          "member" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~
               dgettext(
                 "account",
                 "A link to confirm your email change has been sent to the new address."
               )

      assert Accounts.get_member_by_email(member.email)
    end

    test "将附带非法数据的错误渲染 (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "member" => %{"email" => "with spaces"}
        })

      title = dgettext("account", "Change Email")
      msg = Gettext.dgettext(HanaShirabe.Gettext, "account", "must have the @ sign and no spaces")
      assert result =~ title
      assert result =~ msg
    end

    test "将附带非法数据的错误渲染 (phx-submit)", %{conn: conn, member: member} do
      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

      result =
        lv
        |> form("#email_form", %{
          "member" => %{"email" => member.email}
        })
        |> render_submit()

      title = dgettext("account", "Change Email")
      msg = Gettext.dgettext(HanaShirabe.Gettext, "account", "did not change")
      assert result =~ title
      assert result =~ msg
    end
  end

  describe "更新密码的表单" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end

    test "更新成员密码", %{conn: conn, member: member} do
      new_password = valid_member_password()

      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

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

      assert redirected_to(new_password_conn) == ~p"/me/sensitive-settings"

      assert get_session(new_password_conn, :member_token) != get_session(conn, :member_token)

      update_msg = dgettext("account", "Password updated successfully.")

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~ update_msg

      assert Accounts.get_member_by_email_and_password(member.email, new_password)
    end

    test "将附带非法数据的错误渲染 (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "member" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      button_msg = dgettext("account", "Save Password")
      too_less_msg = dgettext("errors", "should be at least %{count} character(s)", count: 12)
      notmatch_msg = Gettext.dgettext(HanaShirabe.Gettext, "account", "does not match password")

      assert result =~ button_msg
      assert result =~ too_less_msg
      assert result =~ notmatch_msg
    end

    test "将附带非法数据的错误渲染 (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/sensitive-settings")

      result =
        lv
        |> form("#password_form", %{
          "member" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      button_msg = dgettext("account", "Save Password")
      too_less_msg = dgettext("errors", "should be at least %{count} character(s)", count: 12)
      notmatch_msg = Gettext.dgettext(HanaShirabe.Gettext, "account", "does not match password")

      assert result =~ button_msg
      assert result =~ too_less_msg
      assert result =~ notmatch_msg
    end
  end

  describe "确认邮件" do
    setup %{conn: conn} do
      member = member_fixture()
      email = unique_member_email()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(
            %{member | email: email},
            member.email,
            url
          )
        end)

      %{conn: log_in_member(conn, member), token: token, email: email, member: member}
    end

    test "更新一次邮件", %{conn: conn, member: member, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/sensitive-settings"
      assert %{"info" => message} = flash
      assert message == dgettext("account", "Email changed successfully.")
      refute Accounts.get_member_by_email(member.email)
      assert Accounts.get_member_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/sensitive-settings"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "Email change link is invalid or it has expired.")
    end

    test "令牌不合法不要更新邮件", %{conn: conn, member: member} do
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/me/sensitive-settings"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "Email change link is invalid or it has expired.")
      assert Accounts.get_member_by_email(member.email)
    end

    test "成员未登录将会跳转", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/me/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      assert %{"error" => message} = flash
      assert message == dgettext("account", "You must log in to access this page.")
    end
  end
end
