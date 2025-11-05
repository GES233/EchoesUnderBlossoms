defmodule HanaShirabeWeb.LocaleController do
  use HanaShirabeWeb, :controller

  def update(conn, %{"locale" => locale}) do
    conn |> put_resp_cookie("_hana_shirabe_web_locale", locale) |> send_resp(204, "")
  end
end
