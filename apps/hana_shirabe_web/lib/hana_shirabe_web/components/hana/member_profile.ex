defmodule HanaShirabeWeb.Hana.MemberProfile do
  @moduledoc """
  负责将用户信息的代码的模块服用起来，包括自己的主页以及对方的主页
  （前者需要修改按钮，后者需要社交功能的按钮）。
  """
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  # alias Phoenix.LiveView.JS

  attr :member, HanaShirabe.Accounts.Member, required: true

  def show_member(assigns) do
    ~H"""
    <% # 巴拉巴拉 %>
    """
  end
end
