defmodule HanaShirabeWeb.PageControllerTest do
  use HanaShirabeWeb.ConnCase

  use Gettext, backend: HanaShirabeWeb.Gettext

  # 首页肯定会改
  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    msg = gettext("Under construction...")
    assert html_response(conn, 200) =~ msg
  end
end
