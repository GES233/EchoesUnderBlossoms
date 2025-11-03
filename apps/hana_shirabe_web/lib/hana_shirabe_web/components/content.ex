defmodule HanaShirabeWeb.Content do
  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  ## TODO
  # 需要定义外部 container 的大小
  # 同时也包括事件的名称

  def editor(assigns, :easymde) do
    ~H"""
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
    """
  end

  def editor(assigns, :quill) do
    ~H"""
    <div id="editor-container" phx-hook=".QuillEditor" phx-update="ignore">
      <div id="editor"></div>
    </div>
     <link href="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js">
    </script>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".QuillEditor">
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
    """
  end

  ## TODO
  # 渲染相关
end
