defmodule HanaShirabeWeb.MemberSessionControllerTest do
  use HanaShirabeWeb.ConnCase

  import HanaShirabe.AccountsFixtures
  alias HanaShirabe.Accounts

  setup do
    %{unconfirmed_member: unconfirmed_member_fixture(), member: member_fixture()}
  end

  describe "POST /members/log-in - email and password" do
    test "logs the member in", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        post(conn, ~p"/members/log-in", %{
          "member" => %{"email" => member.email, "password" => valid_member_password()}
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/members/settings"
      assert response =~ ~p"/members/log-out"
    end

    test "logs the member in with remember me", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        post(conn, ~p"/members/log-in", %{
          "member" => %{
            "email" => member.email,
            "password" => valid_member_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_hana_shirabe_web_member_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the member in with return to", %{conn: conn, member: member} do
      member = set_password(member)

      conn =
        conn
        |> init_test_session(member_return_to: "/foo/bar")
        |> post(~p"/members/log-in", %{
          "member" => %{
            "email" => member.email,
            "password" => valid_member_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with invalid credentials", %{conn: conn, member: member} do
      conn =
        post(conn, ~p"/members/log-in?mode=password", %{
          "member" => %{"email" => member.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/members/log-in"
    end
  end

  describe "POST /members/log-in - magic link" do
    test "logs the member in", %{conn: conn, member: member} do
      {token, _hashed_token} = generate_member_magic_link_token(member)

      conn =
        post(conn, ~p"/members/log-in", %{
          "member" => %{"token" => token}
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/members/settings"
      assert response =~ ~p"/members/log-out"
    end

    test "confirms unconfirmed member", %{conn: conn, unconfirmed_member: member} do
      {token, _hashed_token} = generate_member_magic_link_token(member)
      refute member.confirmed_at

      conn =
        post(conn, ~p"/members/log-in", %{
          "member" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :member_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Member confirmed successfully."

      assert Accounts.get_member!(member.id).confirmed_at

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ member.email
      assert response =~ ~p"/members/settings"
      assert response =~ ~p"/members/log-out"
    end

    test "redirects to login page when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/members/log-in", %{
          "member" => %{"token" => "invalid"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/members/log-in"
    end
  end

  describe "DELETE /members/log-out" do
    test "logs the member out", %{conn: conn, member: member} do
      conn = conn |> log_in_member(member) |> delete(~p"/members/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :member_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the member is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/members/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :member_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
