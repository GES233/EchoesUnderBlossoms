defmodule HanaShirabeWeb.LocaleController do
  use HanaShirabeWeb, :controller

  # 需要确定的是
  # Cookie 的优先级低于 ?locale=(...) 以及用户设置
  def update(conn, %{"locale" => locale}) do
    conn |> HanaShirabeWeb.SetLocale.persist(locale) |> send_resp(204, "")
  end
end
