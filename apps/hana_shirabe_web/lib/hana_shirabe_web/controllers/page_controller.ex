defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def show(conn, _params) do
    render(conn, :show)
  end
end
