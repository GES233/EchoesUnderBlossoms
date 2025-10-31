defmodule HanaShirabeWeb.PageControllerTest do
  use HanaShirabeWeb.ConnCase

  # 首页肯定会改
  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
