defmodule HanaShirabeWeb.MemberLive.ProfileTest do
  use HanaShirabeWeb.ConnCase

  alias HanaShirabe.Accounts
  import Phoenix.LiveViewTest
  import HanaShirabe.AccountsFixtures

  use Gettext, backend: HanaShirabeWeb.Gettext

  describe "成员个人资料页面" do
    test "渲染个人资料页面", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/me/profile")

      assert html =~ dgettext("account", "Account Profile")
      assert html =~ dgettext("account", "Edit Profile")
    end

    test "成员未登录会被重定向", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/me/profile")

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
        |> live(~p"/me/profile")

      assert html =~ dgettext("account", "Account Profile")
    end
  end

  describe "更新信息表单" do
    setup %{conn: conn} do
      member = member_fixture()
      %{conn: log_in_member(conn, member), member: member}
    end

    test "成功更新成员信息", %{conn: conn, member: member} do
      {:ok, lv, html} = live(conn, ~p"/me/profile")
      assert html =~ member.nickname

      # 点击 "Edit Profile" 按钮进入编辑模式
      html =
        lv
        |> element("button", dgettext("account", "Edit Profile"))
        |> render_click()

      assert html =~ dgettext("account", "Update Profile")
      assert html =~ gettext("Cancel")

      new_nickname = "NewNickname"
      new_intro = "This is a new introduction."

      # 提交表单
      result =
        lv
        |> form(
          "#profile_form",
          %{
            "profile_form" => %{
              "nickname" => new_nickname,
              "intro" => new_intro
            }
          }
        )
        |> render_submit()

      # 确认成功信息
      assert result =~ gettext("Profile updated!")
      # 确认页面已返回展示模式，并显示新昵称
      assert result =~ new_nickname
      assert result =~ new_intro
      refute result =~ dgettext("account", "Update Profile")

      # 确认数据库中的数据已更新
      updated_member = Accounts.get_member!(member.id)
      assert updated_member.nickname == new_nickname
      assert updated_member.intro == new_intro
    end

    test "因非法数据渲染错误 (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/me/profile")

      # 进入编辑模式
      lv
      |> element("button", dgettext("account", "Edit Profile"))
      |> render_click()

      # 触发 phx-change
      result =
        lv
        |> element("#profile_form")
        |> render_change(%{"profile_form" => %{"nickname" => ""}})

      assert result =~ dgettext("errors", "can't be blank")
    end

    test "因非法数据渲染错误 (phx-submit)", %{conn: conn, member: member} do
      {:ok, lv, _html} = live(conn, ~p"/me/profile")

      # 进入编辑模式
      lv
      |> element("button", dgettext("account", "Edit Profile"))
      |> render_click()

      # 触发 phx-submit
      result =
        lv
        |> form("#profile_form", %{
          "profile_form" => %{"nickname" => member.nickname, "intro" => ""}
        })
        |> render_submit(%{"profile_form" => %{"nickname" => ""}})

      assert result =~ dgettext("errors", "can't be blank")
      # 确认页面仍在编辑模式
      assert result =~ dgettext("account", "Update Profile")
    end

    test "点击取消按钮返回展示模式", %{conn: conn, member: member} do
      {:ok, lv, _html} = live(conn, ~p"/me/profile")

      # 进入编辑模式
      html =
        lv
        |> element("button", dgettext("account", "Edit Profile"))
        |> render_click()

      assert html =~ dgettext("account", "Update Profile")

      # 点击取消
      result =
        lv
        |> element("button", gettext("Cancel"))
        |> render_click()

      # 确认回到展示模式
      assert result =~ member.nickname
      assert result =~ dgettext("account", "Edit Profile")
      refute result =~ dgettext("account", "Update Profile")
    end
  end
end
