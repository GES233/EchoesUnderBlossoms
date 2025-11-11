defmodule HanaShirabeWeb.ContentLiveRender do
  use HanaShirabeWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <link rel="stylesheet" href="https://unpkg.com/easymde/dist/easymde.min.css" />
        <style>
          /* Add dark theme to override. */
          .editor-wrapper,
          .CodeMirror,
          .editor-preview,
          .editor-preview-side {
            background-color: #282c34; /* Dark background */
            color: #abb2bf; /* Light text color */
            border-color: #3b4048; /* Darker border */
          }

          .editor-toolbar {
            background-color: #3e4451; /* Dark toolbar background */
            border-bottom-color: #3b4048;
          }

          .editor-toolbar button {
            color: #abb2bf; /* Light icon color */
          }

          .editor-toolbar button.active,
          .editor-toolbar button:hover {
            background-color: #5c6370; /* Hover/active background */
          }

          /* Add more specific styles as needed for elements like the cursor, links, etc. */
          .cm-s-easymde .CodeMirror-cursor {
            border-left-color: #abb2bf; /* Cursor color */
          }
        </style>

        <h2 class="text-xl font-semibold mb-2">EasyMDE Editor</h2>

        <div phx-hook=".EasyMDEditor" id="editor-container" phx-update="ignore">
          <textarea id="markdown-editor"></textarea>
        </div>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".EasyMDEditor">
          const EasyMDE = require('@/vendor/easymde.min.js');
          console.log(EasyMDE);

          export default {
            mounted() {
              const editorEl = this.el.querySelector('#markdown-editor');
              if (!editorEl) return;

              const initContent = "## Hi here!\n\nWelcome to the playground with `MDEx` and `EasyMDE!`.\n\n```elixir\ndefmodule Foo do\n  @moduledoc \"My name na ...\"\n  defstruct :bar\n  def bar!(), do: raise\nend\n```";

              // 初始化 EasyMDE
              const easyMDE = new EasyMDE({
                element: editorEl,
                initialValue: initContent,
                spellChecker: false,
                toolbar: ["bold", "italic", "heading", "quote", "code", "|", "fullscreen"],
              });

              // 监听编辑器的 change 事件
              easyMDE.codemirror.on("change", () => {
                // 获取编辑器中的 Markdown 内容
                const markdown = easyMDE.value();
                // 直接将 Markdown 发送到服务器
                this.pushEvent("content_updated", { markdown: markdown });
              });
            }
          }
        </script>
      </div>

      <div>
        <h2 class="text-xl font-semibold mb-2">Live HTML Preview (from MDEx)</h2>

        <div class="prose max-w-none p-4 border rounded-md min-h-[400px]">
          {@foo |> MDEx.to_html!(render: [escape: true]) |> raw()}
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    default_content = """
    ## Hi here!

    Welcome to the playground with `MDEx` and `EasyMDE!`.

    ```elixir
    defmodule Foo do
      @moduledoc "My name na ..."
      defstruct :bar

      def bar!(), do: raise
    end
    ```
    """

    IO.inspect(socket.assigns, label: "Assigns during mount")

    {:ok, assign(socket, :foo, MDEx.new(markdown: default_content))}
  end

  def handle_event("content_updated", %{"markdown" => markdown}, socket) do
    # IO.inspect(markdown)
    # 流程: Delta -> Markdown -> HTML
    #
    # html = MDEx.to_html!(markdown, extension: [strikethrough: true, table: true, tasklist: true], syntax_highlight: [formatter: {:html_inline, theme: "github_dark"}])

    # 更新 live_preview, LiveView 会自动将变更推送到浏览器
    socket = assign(socket, :foo, markdown)

    {:noreply, socket}
  end
end
