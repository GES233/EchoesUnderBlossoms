defmodule HanaShirabeWeb.MemberAuth do
  use HanaShirabeWeb, :verified_routes
  use Gettext, backend: HanaShirabeWeb.Gettext

  import Plug.Conn
  import Phoenix.Controller

  alias HanaShirabe.Accounts
  alias HanaShirabe.Accounts.Scope

  # “记住我”的 cookie 有效期为与 MemberToken 中的会话有效期设置相匹配。
  @max_cookie_age_in_days Accounts.MemberToken.get_session_validity_in_days()
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

  重定向至会话的 `:member_return_to` 路径
  或回退到 `signed_in_path/1`。
  """
  def log_in_member(conn, member, params \\ %{}) do
    member_return_to = get_session(conn, :member_return_to)

    conn
    |> create_or_extend_session(member, params)
    |> redirect(to: member_return_to || signed_in_path(conn))
  end

  @doc """
  登出。

  清理所有会话数据以确保安全。见 renew_session/2 。
  """
  def log_out_member(conn) do
    member_token = get_session(conn, :member_token)

      case conn.assigns[:audit_log] do
        nil -> member_token && Accounts.delete_member_session_token(member_token)
          %HanaShirabe.AuditLog{} -> member_token && Accounts.logout_member_in_purpose_with_log(conn.assigns[:audit_log], member_token)
      end

    if live_socket_id = get_session(conn, :live_socket_id) do
      HanaShirabeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  通过 session 和「记住我」令牌进行成员认证。

  将在令牌超过配置的年龄后重新发放会话令牌。
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

  # 一旦令牌太久了，就会创建一个新的会话令牌，并且会话 cookie
  # 和“记住我”cookie（如果设置）将使用新令牌进行更新。
  defp maybe_reissue_member_session_token(conn, member, token_inserted_at) do
    token_age = NaiveDateTime.diff(NaiveDateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, member, %{})
    else
      conn
    end
  end

  # 此功能负责创建会话令牌并将其安全地存储在会话和 cookie 中。它可以在登录时、
  # sudo 模式期间或续订即将过期的会话时调用。
  #
  # 当会话建立时，而不是扩展时，renew_session 函数将清除会话以避免固定攻击。
  # 请参阅 renew_session/2 函数以自定义此行为。
  defp create_or_extend_session(conn, member, params) do
    token = Accounts.generate_member_session_token(member)
    remember_me = get_session(conn, :member_remember_me)

    conn
    |> renew_session(member)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # 不要在成员已经登录的情况下续订会话，以防止仍然打开的标签页中出现 CSRF 错误或数据丢失
  defp renew_session(conn, member) when conn.assigns.current_scope.member.id == member.id do
    conn
  end

  # 此函数续订会话 ID 并清除整个会话以避免固定攻击。如果会话中有任何数据
  # 您可能希望在登录/注销后保留，您必须在清除之前显式获取会话数据，
  # 然后在清除后立即设置它，例如：
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
  断开给定令牌现有的 socket 连接。
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      HanaShirabeWeb.Endpoint.broadcast(member_session_topic(token), "disconnect", %{})
    end)
  end

  defp member_session_topic(token), do: "members_sessions:#{Base.url_encode64(token)}"

  @doc """
  负责处理 LiveView 中的 current_scope 的挂载和认证。

  ## `on_mount` 挂载选项

    * `:mount_current_scope` - 将「当前范围」（current_scope）基于
      member_token 分配到 socket assigns 中，如果没有 member_token
      或没有匹配的成员，则为 nil。

    * `:require_authenticated` - 根据会话认证成员，并且将
      current_scope 分配到 socket assigns 中。
      如果没有已登录的成员，则重定向到登录页面。

    * `:require_sudo_mode` - 根据会话认证成员，并且确保成员
      处于 sudo 模式（最近重新认证过）。

    * `:mount_scope_and_audit_log` - （未实现）将 current_scope
      和 audit_log 分配到 socket assigns 中。

  ## Examples

  使用 `on_mount` 生命周期宏在 LiveViews 中挂载或认证 `current_scope`：

      defmodule HanaShirabeWeb.PageLive do
        use HanaShirabeWeb, :live_view

        on_mount {HanaShirabeWeb.MemberAuth, :mount_current_scope}
        ...
      end

  或使用 `live_session` 在路由器中调用 on_mount 回调：

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
      require_login_msg = dgettext("account", "You must log in to access this page.")

      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, require_login_msg)
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Accounts.sudo_mode?(socket.assigns.current_scope.member, -10) do
      {:cont, socket}
    else
      require_authenticate_msg = dgettext("account", "You must re-authenticate to access this page.")

      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, require_authenticate_msg)
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  def mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {member, _} =
        if member_token = session["member_token"] do
          Accounts.get_member_by_session_token(member_token)
        end || {nil, nil}

      Scope.for_member(member)
    end)
  end

  @doc "返回登陆后的重定向路径。"
  # 成员以及登录了，重定向到设置页面
  def signed_in_path(%Plug.Conn{assigns: %{current_scope: %Scope{member: %Accounts.Member{}}}}) do
    ~p"/me/settings"
  end

  def signed_in_path(_), do: ~p"/"

  @doc """
  用于需要成员认证的路由的 Plug 。
  """
  def require_authenticated_member(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.member do
      conn
    else
      require_login_msg = dgettext("account", "You must log in to access this page.")

      conn
      |> put_flash(:error, require_login_msg)
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
