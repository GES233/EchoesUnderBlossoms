defmodule HanaShirabeWeb.MemberLive.RegistrationTest do
  use HanaShirabeWeb.ConnCase

  use Gettext, backend: HanaShirabeWeb.Gettext

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  describe "注册页" do
    test "渲染注册页面", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/sign_up")

      register = dgettext("account", "Register")
      login_msg = dgettext("account", "Log in")

      assert html =~ register
      assert html =~ login_msg
    end

    test "如果已经重录将重定向", %{conn: conn} do
      result =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/sign_up")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "数据不合法渲染错误", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/sign_up")

      result =
        lv
        |> element("#registration_form")
        |> render_change(member: %{"email" => "with spaces"})

      title = dgettext("account", "Register")

      # 因为这是来自另一个应用（HanaShirabe）的信息
      # 因此这里需要显式声明来源
      info = dgettext("errors", "must have the @ sign and no spaces")

      assert result =~ title
      assert result =~ info
    end
  end

  describe "注册成员" do
    test "创建账号但不登录", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/sign_up")

      email = unique_member_email()
      form = form(lv, "#registration_form", member: valid_member_attributes(email: email))

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/login")

      {:ok, check_regex} =
        dgettext(
          "account",
          "An email was sent to %{member_email}, please access it to confirm your account.",
          member_email: ~s(.*)
        )
        |> Regex.compile()

      assert html =~ check_regex
    end

    test "邮件重复返回错误", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/sign_up")

      member = member_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          member: %{"email" => member.email}
        )
        |> render_submit()

      msg = dgettext("errors", "has already been taken")

      assert result =~ msg
    end
  end

  describe "注册导航" do
    test "登录按钮被点击将重定向至登录", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/sign_up")

      element_name = dgettext("account", "Log in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", element_name)
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert login_html =~ element_name
    end
  end
end
