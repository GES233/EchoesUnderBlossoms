defmodule HanaShirabeWeb.QuillMDExPlayground do
  use HanaShirabeWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
      <%= @foo |> MDEx.to_html!(render: [escape: true]) |> raw() %>
    </div>

    <!-- Add QuillJS Editor here. -->
    """
  end

  def mount(_params, _session, socket) do
    default_content = """
    ## Hi here!

    Welcome to the playground with `MDEx` and `QuillJS`.

    ```elixir
    defmodule Foo do
      @moduledoc "My name na ..."
      defstruct :bar

      def bar!(), do: raise
    end
    ```
    """

    {:ok, assign(socket, :foo, MDEx.new(markdown: default_content))}
  end
end
