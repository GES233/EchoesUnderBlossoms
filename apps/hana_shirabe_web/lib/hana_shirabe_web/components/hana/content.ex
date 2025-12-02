defmodule HanaShirabeWeb.Content do
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  # alias Phoenix.LiveView.JS

  @doc """
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

  defp theme_class(:archaiologia), do: "archaiologia"
  defp theme_class(:minimalism), do: "minimalism"
  defp theme_class(:non_ugc), do: "non-ugc"
end
