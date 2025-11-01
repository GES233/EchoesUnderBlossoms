defmodule HanaShirabeWeb.Plugs.SetLocale do
  import Plug.Conn

  # 定义 cookie 的 key
  @locale_cookie "_hana_shirabe_web_locale"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = determine_locale(conn)

    Gettext.put_locale(locale)

    conn
    |> assign(:locale, locale)
    |> put_resp_cookie(@locale_cookie, locale, max_age: 365 * 24 * 60 * 60)
  end

  defp determine_locale(conn) do
    available_locales = Gettext.known_locales(HanaShirabeWeb.Gettext)

    [
      conn.params["locale"],
      # TODO: 实现用户偏好
      # conn.assigns.current_scope && conn.assigns.current_scope.member.prefer_lang,
      conn.req_cookies[@locale_cookie],
      get_req_header(conn, "Accept-Language") |> hd() |> parse_accept_language()
    ]
    |> Enum.find(Gettext.get_locale(), &(&1 in available_locales))
  end

  defp parse_accept_language(<<>>), do: nil
  defp parse_accept_language(header) when is_binary(header) do
    # TODO: 考虑权重
    header
    |> String.split(",")
    |> List.first()
    |> String.split(";")
    |> List.first()
    |> String.replace("-", "_")
  end
end
