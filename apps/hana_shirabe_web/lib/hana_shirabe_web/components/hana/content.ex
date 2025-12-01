defmodule HanaShirabeWeb.Content do
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  # alias Phoenix.LiveView.JS

  # TODO: implement options
  # attr :other_class, :map
  slot :inner, required: true

  def render_inner(assigns) do
    ~H"""
    <div class="prose"><% @inner |> raw() %></div>
    """
  end
end
