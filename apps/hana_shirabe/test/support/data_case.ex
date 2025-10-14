defmodule HanaShirabe.DataCase do
  @moduledoc """
  这个模块定义了需要访问应用程序数据层的测试的设置。

  你可以在这里定义函数，以便在测试中使用。

  最后，如果测试用例与数据库交互，我们启用 SQL 沙箱，
  因此对数据库的更改会在每个测试结束时被还原。
  如果你使用的是 PostgreSQL，你甚至可以通过设置
  `use HanaShirabe.DataCase, async: true` 来异步运行数据库测试，
  尽管这个选项不推荐用于其他数据库。
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias HanaShirabe.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import HanaShirabe.DataCase
    end
  end

  setup tags do
    HanaShirabe.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  基于测试标签设置沙箱。
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HanaShirabe.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  转换 changeset 错误为消息映射的辅助函数。

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
