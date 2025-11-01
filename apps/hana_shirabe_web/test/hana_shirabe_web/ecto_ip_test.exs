defmodule HanaShirabe.EctoIPTest do
  use ExUnit.Case, async: true

  alias HanaShirabe.EctoIP

  describe "cast/1" do
    test "当输入是有效的 IPv4 字符串时，返回 {:ok, string}" do
      assert EctoIP.cast("127.0.0.1") == {:ok, "127.0.0.1"}
    end

    test "当输入是有效的 IPv6 字符串时，返回 {:ok, string}" do
      assert EctoIP.cast("::1") == {:ok, "::1"}
      assert EctoIP.cast("2001:db8::8a2e:370:7334") == {:ok, "2001:db8::8a2e:370:7334"}
    end

    test "当输入是 Erlang 的 IP 元组 (IPv4) 时，返回 {:ok, string}" do
      assert EctoIP.cast({127, 0, 0, 1}) == {:ok, "127.0.0.1"}
    end

    test "当输入是 Erlang 的 IP 元组 (IPv6) 时，返回 {:ok, string}" do
      assert EctoIP.cast({0, 0, 0, 0, 0, 0, 0, 1}) == {:ok, "::1"}
    end

    test "当输入是无效的 IP 字符串时，返回 :error" do
      assert EctoIP.cast("999.999.999.999") == :error
      assert EctoIP.cast("not-an-ip") == :error
    end

    test "当输入是无效的 IP 元组时，返回 :error" do
      # 元组长度不正确
      assert EctoIP.cast({127, 0, 0}) == :error
    end

    test "当输入是其他类型时，返回 :error" do
      assert EctoIP.cast(123) == :error
      assert EctoIP.cast([127, 0, 0, 1]) == :error
      assert EctoIP.cast(%{}) == :error
    end
  end

  describe "load/1" do
    test "当从数据库加载有效的 IP 字符串时，返回 {:ok, tuple}" do
      assert EctoIP.load("192.168.1.1") == {:ok, {192, 168, 1, 1}}
      assert EctoIP.load("::1") == {:ok, {0, 0, 0, 0, 0, 0, 0, 1}}
    end

    test "当从数据库加载无效的 IP 字符串时，返回 :error" do
      assert EctoIP.load("invalid-ip-from-db") == :error
    end

    # Ecto.Type 的 load 函数只期望接收数据库的原生类型，
    # 在这个例子中是字符串 (binary)，所以我们不需要测试其他输入类型。
  end

  describe "dump/1" do
    test "当向数据库转储 IP 元组时，返回 {:ok, string}" do
      assert EctoIP.dump({127, 0, 0, 1}) == {:ok, "127.0.0.1"}
      assert EctoIP.dump({0, 0, 0, 0, 0, 0, 0, 1}) == {:ok, "::1"}
    end

    test "当向数据库转储已经是字符串的 IP 时，直接返回 {:ok, string}" do
      # 这种情况可能发生在 changeset 中传递了字符串而不是元组
      assert EctoIP.dump("127.0.0.1") == {:ok, "127.0.0.1"}
    end

    test "当向数据库转储无效的元组时，返回 :error" do
      # :inet.ntoa/1 会返回一个 charlist 错误，但我们的函数会捕获并返回 :error
      # 这里我们依赖于之前的 cast 测试，dump 的逻辑相对简单
      # 实际 :inet.ntoa 会抛错，但 Ecto.Type 期望返回 {:ok, _} 或 :error
      assert EctoIP.dump({999, 999, 999, 999}) == :error
    end

    test "当向数据库转储其他类型时，返回 :error" do
      assert EctoIP.dump(123) == :error
      assert EctoIP.dump(%{}) == :error
    end
  end
end

defmodule HanaShirabe.EctoIPTestSchema do
  use ExUnit.Case, async: true

  use Ecto.Schema
  import Ecto.Changeset

  import HanaShirabe.DataCase

  alias HanaShirabe.EctoIP
  alias HanaShirabe.EctoIPTestSchema, as: TestSchema

  @primary_key false
  schema "test_ecto_ip" do
    field(:ip, EctoIP)
  end

  def changeset(struct, attrs) do
    cast(struct, attrs, [:ip])
  end

  describe "Ecto.Changeset integration" do
    test "使用有效的 IP 字符串创建 changeset" do
      changeset = TestSchema.changeset(%TestSchema{}, %{ip: "127.0.0.1"})
      assert changeset.valid?
      assert get_field(changeset, :ip) == "127.0.0.1"
    end

    test "使用有效的 IP 元组创建 changeset" do
      changeset = TestSchema.changeset(%TestSchema{}, %{ip: {127, 0, 0, 1}})
      assert changeset.valid?
      assert get_field(changeset, :ip) == "127.0.0.1"
    end

    test "使用无效的 IP 字符串创建 changeset" do
      changeset = TestSchema.changeset(%TestSchema{}, %{ip: "invalid"})
      # Ecto 的 cast/4 会将 :error 转换为一个无效的 changeset
      refute changeset.valid?
      assert errors_on(changeset) == %{ip: ["is invalid"]}
    end
  end
end
