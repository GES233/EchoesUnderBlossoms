defmodule HanaShirabeWeb.AuditLogInjectorTest do
  use HanaShirabeWeb.ConnCase

  # alias Phoenix.LiveView
  import HanaShirabe.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, HanaShirabeWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{member: %{member_fixture() | authenticated_at: NaiveDateTime.utc_now(:second)}, conn: conn}
  end

  describe "put_audit_context/2" do
    # test "会话中的成员将会被装载"

    # test "会话无成员依旧存在事务记录"

    # test "会话无成员不会被装载"
  end

  describe "on_mount :mount_audit_log" do
    # ...
  end
end
