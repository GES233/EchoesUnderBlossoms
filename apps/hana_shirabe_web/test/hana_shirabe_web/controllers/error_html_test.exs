defmodule HanaShirabeWeb.ErrorHTMLTest do
  use HanaShirabeWeb.ConnCase, async: true

  # 将 render_to_string/4 用于测试自定义的 views
  import Phoenix.Template, only: [render_to_string: 4]

  test "渲染 404.html" do
    assert render_to_string(HanaShirabeWeb.ErrorHTML, "404", "html", []) == "Not Found"
  end

  test "渲染 500.html" do
    assert render_to_string(HanaShirabeWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
