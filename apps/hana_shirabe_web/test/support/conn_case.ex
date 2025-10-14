defmodule HanaShirabeWeb.ConnCase do
  @moduledoc """
  此模块定义了需要设置连接的测试所使用的测试用例。

  这些测试需要 `Phoenix.ConnTest` 并且引入了其他的功能，
  使构建通用数据结构和查询数据层变得更加容易。

  最后，如果测试用例需要与数据库交互，我们启用 SQL 沙盒，
  因此对数据库的更改在测试结束后会恢复。如果你用的是
  PostgreSQL ，你甚至可以通过设置
  `use HanaShirabeWeb.ConnCase, async: true`
  对数据库进行异步测试，其他的数据库并不支持此功能。
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # 测试的默认端点
      @endpoint HanaShirabeWeb.Endpoint

      use HanaShirabeWeb, :verified_routes

      # 方便测试时的连接
      import Plug.Conn
      import Phoenix.ConnTest
      import HanaShirabeWeb.ConnCase
    end
  end

  setup tags do
    HanaShirabe.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
