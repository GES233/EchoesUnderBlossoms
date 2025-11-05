defmodule HanaShirabeWeb.MemberAuthTest do
  use HanaShirabeWeb.ConnCase

  use Gettext, backend: HanaShirabeWeb.Gettext

  alias Phoenix.LiveView
  alias HanaShirabe.Accounts
  alias HanaShirabe.Accounts.Scope
  alias HanaShirabeWeb.{MemberAuth, AuditLogInjector}

  import HanaShirabe.AccountsFixtures

  @remember_me_cookie "_hana_shirabe_web_member_remember_me"
  @remember_me_cookie_max_age 60 * 60 * 24 * 14

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, HanaShirabeWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{member: %{member_fixture() | authenticated_at: NaiveDateTime.utc_now(:second)}, conn: conn}
  end

  describe "log_in_member/3" do
    test "将成员令牌保存到会话中", %{conn: conn, member: member} do
      conn = MemberAuth.log_in_member(conn, member)
      assert token = get_session(conn, :member_token)
      assert get_session(conn, :live_socket_id) == "members_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_member_by_session_token(token)
    end

    test "清理此前会话的所有内容", %{conn: conn, member: member} do
      conn = conn |> put_session(:to_be_removed, "value") |> MemberAuth.log_in_member(member)
      refute get_session(conn, :to_be_removed)
    end

    test "keeps session when re-authenticating", %{conn: conn, member: member} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_member(member))
        |> put_session(:to_be_removed, "value")
        |> MemberAuth.log_in_member(member)

      assert get_session(conn, :to_be_removed)
    end

    test "clears session when member does not match when re-authenticating", %{
      conn: conn,
      member: member
    } do
      other_member = member_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_member(other_member))
        |> put_session(:to_be_removed, "value")
        |> MemberAuth.log_in_member(member)

      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, member: member} do
      conn = conn |> put_session(:member_return_to, "/hello") |> MemberAuth.log_in_member(member)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, member: member} do
      conn =
        conn |> fetch_cookies() |> MemberAuth.log_in_member(member, %{"remember_me" => "true"})

      assert get_session(conn, :member_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :member_remember_me) == true

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :member_token)
      assert max_age == @remember_me_cookie_max_age
    end

    test "redirects to settings when member is already logged in", %{conn: conn, member: member} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_member(member))
        |> MemberAuth.log_in_member(member)

      assert redirected_to(conn) == ~p"/me/settings"
    end

    test "writes a cookie if remember_me was set in previous session", %{
      conn: conn,
      member: member
    } do
      conn =
        conn |> fetch_cookies() |> MemberAuth.log_in_member(member, %{"remember_me" => "true"})

      assert get_session(conn, :member_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :member_remember_me) == true

      conn =
        conn
        |> recycle()
        |> Map.replace!(:secret_key_base, HanaShirabeWeb.Endpoint.config(:secret_key_base))
        |> fetch_cookies()
        |> init_test_session(%{member_remember_me: true})

      # the conn is already logged in and has the remember_me cookie set,
      # now we log in again and even without explicitly setting remember_me,
      # the cookie should be set again
      conn = conn |> MemberAuth.log_in_member(member, %{})
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :member_token)
      assert max_age == @remember_me_cookie_max_age
      assert get_session(conn, :member_remember_me) == true
    end
  end

  describe "logout_member/1" do
    test "擦除会话以及 cookies", %{conn: conn, member: member} do
      member_token = Accounts.generate_member_session_token(member)

      HanaShirabe.Accounts.Scope.for_member(member)

      conn =
        conn
        |> put_session(:member_token, member_token)
        |> put_req_cookie(@remember_me_cookie, member_token)
        |> fetch_cookies()
        |> assign(:current_scope, HanaShirabe.Accounts.Scope.for_member(member))
        |> AuditLogInjector.put_audit_context()
        |> MemberAuth.log_out_member()

      refute get_session(conn, :member_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_member_by_session_token(member_token)
    end

    test "广播给定 live_socket_id", %{conn: conn} do
      live_socket_id = "members_sessions:abcdef-token"
      HanaShirabeWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> MemberAuth.log_out_member()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "在已登出依旧执行", %{conn: conn} do
      conn = conn |> fetch_cookies() |> MemberAuth.log_out_member()
      refute get_session(conn, :member_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_scope_for_member/2" do
    test "authenticates member from session", %{conn: conn, member: member} do
      member_token = Accounts.generate_member_session_token(member)

      conn =
        conn
        |> put_session(:member_token, member_token)
        |> MemberAuth.fetch_current_scope_for_member([])

      assert conn.assigns.current_scope.member.id == member.id
      assert conn.assigns.current_scope.member.authenticated_at == member.authenticated_at
      assert get_session(conn, :member_token) == member_token
    end

    test "authenticates member from cookies", %{conn: conn, member: member} do
      logged_in_conn =
        conn |> fetch_cookies() |> MemberAuth.log_in_member(member, %{"remember_me" => "true"})

      member_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> MemberAuth.fetch_current_scope_for_member([])

      assert conn.assigns.current_scope.member.id == member.id
      assert conn.assigns.current_scope.member.authenticated_at == member.authenticated_at
      assert get_session(conn, :member_token) == member_token
      assert get_session(conn, :member_remember_me)

      assert get_session(conn, :live_socket_id) ==
               "members_sessions:#{Base.url_encode64(member_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, member: member} do
      _ = Accounts.generate_member_session_token(member)
      conn = MemberAuth.fetch_current_scope_for_member(conn, [])
      refute get_session(conn, :member_token)
      refute conn.assigns.current_scope
    end

    test "reissues a new token after a few days and refreshes cookie", %{
      conn: conn,
      member: member
    } do
      logged_in_conn =
        conn |> fetch_cookies() |> MemberAuth.log_in_member(member, %{"remember_me" => "true"})

      token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      offset_member_token(token, -10, :day)
      {member, _} = Accounts.get_member_by_session_token(token)

      conn =
        conn
        |> put_session(:member_token, token)
        |> put_session(:member_remember_me, true)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> MemberAuth.fetch_current_scope_for_member([])

      assert conn.assigns.current_scope.member.id == member.id
      assert conn.assigns.current_scope.member.authenticated_at == member.authenticated_at
      assert new_token = get_session(conn, :member_token)
      assert new_token != token
      assert %{value: new_signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert new_signed_token != signed_token
      assert max_age == @remember_me_cookie_max_age
    end
  end

  describe "on_mount :mount_current_scope" do
    setup %{conn: conn} do
      %{conn: MemberAuth.fetch_current_scope_for_member(conn, [])}
    end

    test "assigns current_scope based on a valid member_token", %{conn: conn, member: member} do
      member_token = Accounts.generate_member_session_token(member)
      session = conn |> put_session(:member_token, member_token) |> get_session()

      {:cont, updated_socket} =
        MemberAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.member.id == member.id
    end

    test "assigns nil to current_scope assign if there isn't a valid member_token", %{conn: conn} do
      member_token = "invalid_token"
      session = conn |> put_session(:member_token, member_token) |> get_session()

      {:cont, updated_socket} =
        MemberAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end

    test "assigns nil to current_scope assign if there isn't a member_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        MemberAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_authenticated" do
    test "authenticates current_scope based on a valid member_token", %{
      conn: conn,
      member: member
    } do
      member_token = Accounts.generate_member_session_token(member)
      session = conn |> put_session(:member_token, member_token) |> get_session()

      {:cont, updated_socket} =
        MemberAuth.on_mount(:require_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.member.id == member.id
    end

    test "redirects to login page if there isn't a valid member_token", %{conn: conn} do
      member_token = "invalid_token"
      session = conn |> put_session(:member_token, member_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HanaShirabeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = MemberAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end

    test "redirects to login page if there isn't a member_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: HanaShirabeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = MemberAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_sudo_mode" do
    test "allows members that have authenticated in the last 10 minutes", %{
      conn: conn,
      member: member
    } do
      member_token = Accounts.generate_member_session_token(member)
      session = conn |> put_session(:member_token, member_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HanaShirabeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:cont, _updated_socket} =
               MemberAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end

    test "redirects when authentication is too old", %{conn: conn, member: member} do
      eleven_minutes_ago = NaiveDateTime.utc_now(:second) |> NaiveDateTime.add(-11, :minute)
      member = %{member | authenticated_at: eleven_minutes_ago}
      member_token = Accounts.generate_member_session_token(member)
      {member, token_inserted_at} = Accounts.get_member_by_session_token(member_token)
      assert NaiveDateTime.compare(token_inserted_at, member.authenticated_at) == :gt
      session = conn |> put_session(:member_token, member_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HanaShirabeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:halt, _updated_socket} =
               MemberAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end
  end

  describe "require_authenticated_member/2" do
    setup %{conn: conn} do
      %{conn: MemberAuth.fetch_current_scope_for_member(conn, [])}
    end

    test "redirects if member is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> MemberAuth.require_authenticated_member([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               dgettext("account", "You must log in to access this page.")
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> MemberAuth.require_authenticated_member([])

      assert halted_conn.halted
      assert get_session(halted_conn, :member_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> MemberAuth.require_authenticated_member([])

      assert halted_conn.halted
      assert get_session(halted_conn, :member_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> MemberAuth.require_authenticated_member([])

      assert halted_conn.halted
      refute get_session(halted_conn, :member_return_to)
    end

    test "does not redirect if member is authenticated", %{conn: conn, member: member} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_member(member))
        |> MemberAuth.require_authenticated_member([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "disconnect_sessions/1" do
    test "broadcasts disconnect messages for each token" do
      tokens = [%{token: "token1"}, %{token: "token2"}]

      for %{token: token} <- tokens do
        HanaShirabeWeb.Endpoint.subscribe("members_sessions:#{Base.url_encode64(token)}")
      end

      MemberAuth.disconnect_sessions(tokens)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "members_sessions:dG9rZW4x"
      }

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "members_sessions:dG9rZW4y"
      }
    end
  end
end
