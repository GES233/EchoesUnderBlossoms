defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def show(conn, _param), do: render(conn, :show, [assigns: [title_or_role: fn -> "show" end]])
end
