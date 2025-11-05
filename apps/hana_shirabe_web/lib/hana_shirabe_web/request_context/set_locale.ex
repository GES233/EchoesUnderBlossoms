defmodule HanaShirabeWeb.SetLocale do
  import Plug.Conn

  # 定义 cookie 的 key
  @locale_cookie "_hana_shirabe_web_locale"
  @known_locales Gettext.known_locales(HanaShirabeWeb.Gettext)
  @default_locale Gettext.get_locale()

  def get_locale_cookie(), do: @locale_cookie

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || Gettext.get_locale(HanaShirabeWeb.Gettext)

    Gettext.put_locale(HanaShirabeWeb.Gettext, locale)

    {:cont, Phoenix.Component.assign(socket, :locale, locale)}
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = determine_locale(conn)

    Gettext.put_locale(HanaShirabeWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
    |> put_resp_cookie(@locale_cookie, locale, max_age: 365 * 24 * 60 * 60, signed: true)
  end

  def persist(conn, locale) do
    conn
    |> put_session(:locale, locale)
    |> put_resp_cookie(@locale_cookie, locale, max_age: 365 * 24 * 60 * 60, signed: true)
  end

  defp determine_locale(conn) do
    conn
    |> fetch_locale_from_sources()
    |> Enum.find(@default_locale, &(&1 in @known_locales))
  end

  defp fetch_locale_from_sources(conn) do
    [
      # 1. URL 参数优先级最高，用于用户主动切换
      conn.params["locale"],
      # 2. 已登录用户的数据库偏好
      conn.assigns.current_scope && conn.assigns.current_scope.member.prefer_locale,
      # 3. Cookie 中的持久化选择
      conn.req_cookies[@locale_cookie],
      # 4. 浏览器 Accept-Language 头
      get_req_header(conn, "accept-language") |> parse_accept_language()
    ]
  end

  defp parse_accept_language([]), do: nil

  defp parse_accept_language([header | _]) do
    header
    |> String.split(",")
    |> Enum.map(fn part ->
      case String.split(part, ";") do
        [locale | _] ->
          locale |> String.trim() |> String.replace("-", "_")

        _ ->
          nil
      end
    end)
    |> hd()
    |> case do
      "zh_CN" -> "zh_Hans"
      "zh_TW" -> "zh_Hant"
      "zh_HK" -> "zh_Hant"
      other -> other
    end
  end
end
