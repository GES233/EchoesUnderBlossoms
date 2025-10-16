import { Quill } from "../../vendor/quill.js"

export let QuillEditor = {
    mounted() {
    // `this.el` 是带有 phx-hook 属性的 DOM 元素
    const editorEl = this.el.querySelector('#editor');
    if (!editorEl) return;

    // 初始化 Quill
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
      }
    });

    // 监听 text-change 事件
    quill.on('text-change', (delta, oldDelta, source) => {
      // 只处理用户输入 ("user") 的变化，避免无限循环
      if (source == 'user') {
        // 获取编辑器的全部内容 (Delta 格式)
        const contents = quill.getContents();
        // 通过 pushEvent 将 Delta 发送到服务器
        this.pushEvent("quill_updated", { delta: contents });
      }
    });
  }
}
