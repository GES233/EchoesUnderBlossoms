defmodule HanaShirabeWeb.MemberLive.RegistrationTest do
  use HanaShirabeWeb.ConnCase

  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/members/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/members/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(member: %{"email" => "with spaces"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register member" do
    test "creates account but does not log in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/register")

      email = unique_member_email()
      form = form(lv, "#registration_form", member: valid_member_attributes(email: email))

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/members/log-in")

      assert html =~
               ~r/An email was sent to .*, please access it to confirm your account/
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/register")

      member = member_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          member: %{"email" => member.email}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/members/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/members/log-in")

      assert login_html =~ "Log in"
    end
  end
end
