defmodule HanaShirabeWeb.QuillMDExPlayground do
  use HanaShirabeWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="p-4 md:p-10">
      <h1 class="text-2xl font-bold mb-4">QuillJS + MDEx Playground</h1>

      <p class="text-gray-600 mb-6">在下面的编辑器中输入内容，内容会以 Quill Delta 的形式发送到服务器，
        服务器将其转换为 Markdown，再用 MDEx 渲染成 HTML 实时预览。</p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

      <!-- Show result -->
      <div>
        <h2 class="text-xl font-semibold mb-2">Live HTML Preview (from MDEx)</h2>

        <div class="prose max-w-none p-4 border rounded-md min-h-[400px]">
          {@foo |> MDEx.to_html!(render: [escape: true]) |> raw()}
        </div>
      </div>

      <!-- Add QuillJS Editor here. -->
      <div>
        <h2 class="text-xl font-semibold mb-2">QuillJS Editor</h2>
        <div id="editor-container" phx-hook=".QuillEditor" phx-update="ignore">
          <div id="editor"></div>
        </div>

        <link href="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css" rel="stylesheet" />
        <script :type={Phoenix.LiveView.ColocatedHook} name=".QuillEditor">
          const Quill = require('@/vendor/quill');

          export default {
            mounted() {
            const editorEl = this.el.querySelector('#editor');
            console.log(editorEl);
            if (!editorEl) return;

            const quill = new Quill(editorEl, {
              theme: 'snow',
              modules: {
                toolbar: [
                  [{ 'header': [1, 2, 3, false] }],
                  ['bold', 'italic', 'underline', 'strike'],
                  [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                  ['link', 'blockquote', 'code-block'],
                  [{ 'color': [] }, { 'background': [] }],
                  ['clean']
                ]
              },
              place_holder: "Blabla",
            });

            // 监听 text-change 事件
            quill.on('text-change', (delta, oldDelta, source) => {
              // 只处理用户输入 ("user") 的变化，避免无限循环
              if (source == 'user') {
                const contents = quill.getContents();
                this.pushEvent("quill_updated", { delta: contents });
              }
            });
            }
            }
          </script>
        </div>
      </div>

    </div>
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

  def handle_event("quill_updated", %{"delta" => delta}, socket) do
    IO.inspect delta
    # 流程: Delta -> Markdown -> HTML
    #
    # html = MDEx.to_html!(markdown, extension: [strikethrough: true, table: true, tasklist: true], syntax_highlight: [formatter: {:html_inline, theme: "github_dark"}])

    # 更新 live_preview, LiveView 会自动将变更推送到浏览器
    socket = assign(socket, :live_preview, nil)
    {:noreply, socket}
  end
end
