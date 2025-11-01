defmodule HanaShirabeWeb.ErrorJSONTest do
  use HanaShirabeWeb.ConnCase, async: true

  test "渲染 404" do
    assert HanaShirabeWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "渲染 500" do
    assert HanaShirabeWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
