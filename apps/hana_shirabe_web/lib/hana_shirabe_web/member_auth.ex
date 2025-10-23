defmodule HanaShirabeWeb.MemberAuth do
  use HanaShirabeWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias HanaShirabe.Accounts
  alias HanaShirabe.Accounts.Scope

  # 使“记住我”的 cookie 有效期为 14 天。这应该与 MemberToken 中的会话有效期设置相匹配。
  @max_cookie_age_in_days 14
  @remember_me_cookie "_hana_shirabe_web_member_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # 会话令牌的有效期为多长后才会发放新的令牌。当使用超过此值的会话令牌发出请求时，
  # 将会创建一个新的会话令牌，并且会话 cookie 和“记住我”cookie（如果设置）将使用新令牌进行更新。
  # 降低此值将导致活跃用户创建更多令牌，增加此值将缩短会话令牌过期前用户获得新令牌的时间。
  # 可以将此值设置为大于 `@max_cookie_age_in_days` 的值，以完全禁用重新发放令牌。
  @session_reissue_age_in_days 7

  @doc """
  登录。

  Redirects to the session's `:member_return_to` path
  or falls back to the `signed_in_path/1`.
  """
  def log_in_member(conn, member, params \\ %{}) do
    member_return_to = get_session(conn, :member_return_to)

    conn
    |> create_or_extend_session(member, params)
    |> redirect(to: member_return_to || signed_in_path(conn))
  end

  @doc """
  Logs the member out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_member(conn) do
    member_token = get_session(conn, :member_token)
    member_token && Accounts.delete_member_session_token(member_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      HanaShirabeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the member by looking into the session and remember me token.

  Will reissue the session token if it is older than the configured age.
  """
  def fetch_current_scope_for_member(conn, _opts) do
    with {token, conn} <- ensure_member_token(conn),
         {member, token_inserted_at} <- Accounts.get_member_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_member(member))
      |> maybe_reissue_member_session_token(member, token_inserted_at)
    else
      nil -> assign(conn, :current_scope, Scope.for_member(nil))
    end
  end

  defp ensure_member_token(conn) do
    if token = get_session(conn, :member_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:member_remember_me, true)}
      else
        nil
      end
    end
  end

  # Reissue the session token if it is older than the configured reissue age.
  defp maybe_reissue_member_session_token(conn, member, token_inserted_at) do
    token_age = NaiveDateTime.diff(NaiveDateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, member, %{})
    else
      conn
    end
  end

  # This function is the one responsible for creating session tokens
  # and storing them safely in the session and cookies. It may be called
  # either when logging in, during sudo mode, or to renew a session which
  # will soon expire.
  #
  # When the session is created, rather than extended, the renew_session
  # function will clear the session to avoid fixation attacks. See the
  # renew_session function to customize this behaviour.
  defp create_or_extend_session(conn, member, params) do
    token = Accounts.generate_member_session_token(member)
    remember_me = get_session(conn, :member_remember_me)

    conn
    |> renew_session(member)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # Do not renew session if the member is already logged in
  # to prevent CSRF errors or data being lost in tabs that are still open
  defp renew_session(conn, member) when conn.assigns.current_scope.member.id == member.id do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn, _member) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn, _member) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:member_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:member_token, token)
    |> put_session(:live_socket_id, member_session_topic(token))
  end

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      HanaShirabeWeb.Endpoint.broadcast(member_session_topic(token), "disconnect", %{})
    end)
  end

  defp member_session_topic(token), do: "members_sessions:#{Base.url_encode64(token)}"

  @doc """
  Handles mounting and authenticating the current_scope in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_scope` - Assigns current_scope
      to socket assigns based on member_token, or nil if
      there's no member_token or no matching member.

    * `:require_authenticated` - Authenticates the member from the session,
      and assigns the current_scope to socket assigns based
      on member_token.
      Redirects to login page if there's no logged member.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the `current_scope`:

      defmodule HanaShirabeWeb.PageLive do
        use HanaShirabeWeb, :live_view

        on_mount {HanaShirabeWeb.MemberAuth, :mount_current_scope}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{HanaShirabeWeb.MemberAuth, :require_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.member do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Accounts.sudo_mode?(socket.assigns.current_scope.member, -10) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must re-authenticate to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {member, _} =
        if member_token = session["member_token"] do
          Accounts.get_member_by_session_token(member_token)
        end || {nil, nil}

      Scope.for_member(member)
    end)
  end

  @doc "Returns the path to redirect to after log in."
  # the member was already logged in, redirect to settings
  def signed_in_path(%Plug.Conn{assigns: %{current_scope: %Scope{member: %Accounts.Member{}}}}) do
    ~p"/me/settings"
  end

  def signed_in_path(_), do: ~p"/"

  @doc """
  Plug for routes that require the member to be authenticated.
  """
  def require_authenticated_member(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.member do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :member_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
