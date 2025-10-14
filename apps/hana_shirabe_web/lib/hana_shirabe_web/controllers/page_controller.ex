defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
