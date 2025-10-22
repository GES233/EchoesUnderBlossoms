defmodule HanaShirabeWeb.MemberLive.LoginTest do
  use HanaShirabeWeb.ConnCase

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/members/log-in")

      assert html =~ "Log in"
      assert html =~ "Register"
      assert html =~ "Log in with email"
    end
  end

  describe "member login - magic link" do
    test "sends magic link email when member exists", %{conn: conn} do
      member = member_fixture()

      {:ok, lv, _html} = live(conn, ~p"/members/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", member: %{email: member.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/members/log-in")

      assert html =~ "If your email is in our system"

      assert HanaShirabe.Repo.get_by!(HanaShirabe.Accounts.MemberToken, member_id: member.id).context ==
               "login"
    end

    test "does not disclose if member is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", member: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/members/log-in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "member login - password" do
    test "redirects if member logs in with valid credentials", %{conn: conn} do
      member = member_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/members/log-in")

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
      {:ok, lv, _html} = live(conn, ~p"/members/log-in")

      form =
        form(lv, "#login_form_password", member: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/members/log-in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/log-in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/members/register")

      assert login_html =~ "Register"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      member = member_fixture()
      %{member: member, conn: log_in_member(conn, member)}
    end

    test "shows login page with email filled in", %{conn: conn, member: member} do
      {:ok, _lv, html} = live(conn, ~p"/members/log-in")

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"
      assert html =~ "Log in with email"

      assert html =~
               ~s(<input type="email" name="member[email]" id="login_form_magic_email" value="#{member.email}")
    end
  end
end
