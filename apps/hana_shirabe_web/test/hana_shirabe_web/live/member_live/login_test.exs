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
      login_with_email = dgettext("account", "Log in with email")

      assert html =~ login
      assert html =~ register
      assert html =~ login_with_email
    end
  end

  describe "通过链接登录成员" do
    test "sends magic link email when member exists", %{conn: conn} do
      member = member_fixture()

      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", member: %{email: member.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "If your email is in our system, you will receive instructions for logging in shortly.")

      assert html =~ msg

      assert HanaShirabe.Repo.get_by!(HanaShirabe.Accounts.MemberToken, member_id: member.id).context ==
               "login"
    end

    test "does not disclose if member is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", member: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      msg = dgettext("account", "If your email is in our system, you will receive instructions for logging in shortly.")

      assert html =~ msg
    end
  end

  describe "member login - password" do
    test "redirects if member logs in with valid credentials", %{conn: conn} do
      member = member_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form_password",
          member: %{email: member.email, password: valid_member_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form_password", member: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == dgettext("account", "Invalid email or password")
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      # sign_up_element_name = dgettext("account", "Sign up")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", dgettext("account", "Sign up"))
        |> render_click()
        |> follow_redirect(conn, ~p"/sign_up")

      msg = dgettext("account", "Register")

      assert login_html =~ msg
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      member = member_fixture()
      %{member: member, conn: log_in_member(conn, member)}
    end

    test "shows login page with email filled in", %{conn: conn, member: member} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      info = dgettext("account", "You need to reauthenticate to perform sensitive actions on your account.")
      title = dgettext("account", "Register")
      button = dgettext("account", "Log in with email")

      assert html =~ info
      refute html =~ title
      assert html =~ button

      assert html =~
               ~s(<input type="email" name="member[email]" id="login_form_magic_email" value="#{member.email}")
    end
  end
end
