defmodule HanaShirabeWeb.MemberLive.SettingsTest do
  use HanaShirabeWeb.ConnCase

  alias HanaShirabe.Accounts
  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  use Gettext, backend: HanaShirabeWeb.Gettext

  describe "成员设置页面" do
    test "渲染设置页面", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/me/settings")

      assert html =~ dgettext("account", "Account Settings")
    end

    test "成员未登录会被重定向", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/me/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      %{"error" => message} = flash
      assert message =~ dgettext("account", "You must log in to access this page.")
    end

    test "用户未验证（不在 sudo 模式）【不会】被重定向", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_member(member_fixture(),
          token_authenticated_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/me/settings")

      assert html =~ dgettext("account", "Account Settings")
    end
  end

  describe "更新信息表单" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end
  end

  ## 基本上照着 HanaShirabeWeb.MemberLive.SensitiveSettingsTest 来就可以
end
