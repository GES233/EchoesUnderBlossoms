// 如果你想要使用 Phoenix channcels ，请运行 `mix help phx.gen.channel`
// 并且取消下面这一行代码的注释。
// import "./user_socket.js"

// 你可以通过两种方式来导入依赖项。
//
// 最简单的一种是把代码放在 assets/vendor 里并且通过相对路径来导入：
//
//     import "../vendor/some-package.js"
//
// 或者是，你可以 `npm install some-package --prefix assets` 并且使用
// 包的名字来导入它们：
//
//     import "some-package"
//
// 如果您有尝试导入 CSS 的依赖项，esbuild 将生成一个单独的 `app.css` 文件。
// 要加载它，只需将第二个 `<link>` 添加到您的 `root.html.heex` 文件即可。

// 导入 phoenix_html 来处理表单和按钮中的 method=PUT/DELETE 。
import "phoenix_html"
// 建立 Phoenix Socket 和 LiveView 的配置。
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/hana_shirabe_web"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  // 因为 colocatedHooks 的关系，不再需要建 `/hooks` 文件夹了
  hooks: {...colocatedHooks},
})

// 在表单提交以及 live 引导使用进度条
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// 如果页面有 LiveView 的话，建立连接
liveSocket.connect()

// 暴露 liveSocket 在窗口里，为了 web 控制台调试日志和延迟模拟：
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // 在浏览器会话期间启用
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// 以下代码启用了 phoenix_live_reload 开发功能：
//
//     1. 将服务器日志流式传输到浏览器控制台
//     2. 点击元素即可在代码编辑器中跳转到其定义
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // 启用服务器日志流传输到客户端。
    // 使用 reloader.disableServerLogs() 禁用
    reloader.enableServerLogs()

    // 在被点击元素的 HEEx 组件所在行打开已配置的 PLUG_EDITOR 文件
    //
    // * 按下 "c" 键点击打开调用者位置
    // * 按下 "d" 键点击打开函数组件定义位置
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

