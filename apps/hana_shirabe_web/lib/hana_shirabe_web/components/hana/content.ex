defmodule HanaShirabeWeb.Hana.Content do
  @moduledoc """
  内容容器相关组件。
  """
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  # alias Phoenix.LiveView.JS

  @doc """
  对语义化的 HTML 代码添加样式（基于 tailwindcss/typography）。

  具体样式可参考 assets/css/prose.css 。
  """
  attr :id, :string, default: ""
  attr :theme, :atom, required: true, values: [:archaiologia, :minimalism, :non_ugc]
  attr :other_class, :list, default: []
  slot :inner, required: true

  def render_inner(assigns) do
    ~H"""
    <div data-theme={theme_class(@theme)}>
      <div class={@other_class ++ "prose"} id={@id}>
        <% @inner |> render_slot() %>
      </div>
    </div>
    """
  end

  # 根据主题返回对应的类名。
  defp theme_class(:archaiologia), do: "archaiologia"
  defp theme_class(:minimalism), do: "minimalism"
  defp theme_class(:non_ugc), do: "non-ugc"

  ## TODO: 考虑一些更复杂的格式（脚注双向链接、参考文献，@mention etc.）
end
