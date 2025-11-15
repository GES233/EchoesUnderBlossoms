defmodule HanaShirabeWeb.MemberLive.LoginTest do
  use HanaShirabeWeb.ConnCase

  use Gettext, backend: HanaShirabeWeb.Gettext

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  describe "登录页面" do
    test "渲染登录页面", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      login = dgettext("account", "Log in")
      register = dgettext("account", "Register")
      login_with_email = dgettext("account", "Send code")

      assert html =~ login
      assert html =~ register
      assert html =~ login_with_email
    end
  end

  describe "通过链接登录成员" do
    test "成员存在发送登录链接", %{conn: conn} do
      member = member_fixture()

      {:ok, lv, _html} = live(conn, ~p"/login")

      html =
        form(lv, "#email_login_form", email_login_form: %{email: member.email})
        |> render_submit()

      msg =
        dgettext(
          "account",
          "If your email is in our system, you will receive instructions for logging in shortly."
        )

      assert html =~ msg

      assert HanaShirabe.Repo.get_by!(HanaShirabe.Accounts.MemberToken, member_id: member.id).context ==
               "login"
    end

    test "不会泄露某个邮箱地址是否已被注册", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      html =
        form(lv, "#email_login_form", email_login_form: %{email: "idonotexist@example.com"})
        |> render_submit()

      msg =
        dgettext(
          "account",
          "If your email is in our system, you will receive instructions for logging in shortly."
        )

      assert html =~ msg
    end
  end

  # describe "通过邮件邀请码登录成员"

  describe "通过密码登录成员" do
    test "输入合法凭证将会跳转", %{conn: conn} do
      member = member_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#password_login_form",
          member: %{email: member.email, password: valid_member_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "输入不合法屏障将原地跳转", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#password_login_form",
          password_login_form: %{email: "test@email.com", password: "123456"}
        )

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               dgettext("account", "Invalid email or password")

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "登录导航" do
    test "注册按钮被点击将重定向至注册页面", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      element_name = dgettext("account", "Sign up")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", element_name)
        |> render_click()
        |> follow_redirect(conn, ~p"/sign_up")

      msg = dgettext("account", "Register")

      assert login_html =~ msg
    end
  end

  describe "重新认证用户（sudo 模式）" do
    setup %{conn: conn} do
      member = member_fixture()
      %{member: member, conn: log_in_member(conn, member)}
    end

    test "展示存在邮件输入栏的登录页面", %{conn: conn, member: member} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      info =
        dgettext(
          "account",
          "You need to reauthenticate to perform sensitive actions on your account."
        )

      title = dgettext("account", "Register")
      button = dgettext("account", "Send code")

      assert html =~ info
      refute html =~ title
      assert html =~ button

      assert html =~
               ~s(<input type="email" name="email_login_form[email]" id="email_login_form_email" value="#{member.email}")
    end
  end
end
