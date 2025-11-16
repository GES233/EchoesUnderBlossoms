defmodule HanaShirabeWeb.Hana.MemberProfile do
  @moduledoc """
  负责将用户信息的代码的模块服用起来，包括自己的主页以及对方的主页
  （前者需要修改按钮，后者需要社交功能的按钮）。
  """
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  # alias Phoenix.LiveView.JS


  @doc """
  展示用户信息。

  这个是 Gemini 还是谁搓出来的，需要修改。
  """
  attr :member, HanaShirabe.Accounts.Member, required: true
  slot :inner_block, required: true

  def show_member(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body items-center text-center">
        <!-- <div class="avatar placeholder mb-4">
          <div class="bg-neutral-focus text-neutral-content rounded-full w-24">
            <span class="text-3xl">{String.at(@member.nickname, 0)}</span>
          </div>
        </div> -->
        <h2 class="card-title text-2xl">{@member.nickname}</h2>
        <div class="prose mt-4 text-left">
          <blockquote>
            <%= cond do %>
              <% is_nil(@member.intro) or
                (is_binary(@member.intro) and String.trim(@member.intro) == "") -> %>
                <p class="italic">
                  {dgettext("account", "This member has not yet left an introduction.")}
                </p>
              <% true -> %>
                <p>{@member.intro}</p>
            <% end %>
          </blockquote>
        </div>

        <div class="divider"></div>

        <div class="stats stats-vertical lg:stats-horizontal bg-transparent">
          <div class="stat">
            <div class="stat-title">{dgettext("account", "Joined since")}</div>

            <div class="stat-value text-base">
              {Calendar.strftime(@member.inserted_at, "%Y-%m-%d")}
            </div>
          </div>
        </div>

        <div :if={@inner_block != []} class="card-actions justify-end w-full mt-4">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
