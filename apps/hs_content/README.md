# HSContent

基于 [MDEx](https://mdelixir.dev/) 的内容承载服务，旨在不通过外部应用/程序实现内容的渲染。

## 应用环境

本质上是源于随时跑路的不安全感。

将该功能分离出来作为独立应用的原因，是使用情形的多样性：

1. Markdown -> HTML
  - 最普通最常见的功能
2. Markdown -> Markdown
  - 一般是用户导出数据，对于站内资源，可能会重新组织以及索引

## 路线图

- [x] 实现标准 Markdown 的处理以及渲染
  - 使之可以通过一个函数来实现
  - 要求：「互换两次后的操作」为幂等
    - 需要来源： 数据库内的形式为 Markdown-like with assets annotation
    - 解决方案：只考虑标准 Markdown
- [ ] 添加插件
  - `:mdex_gfm`
- [x] ~~添加自定义 MDEx 插件~~ 操作普通的渲染流
  - 需要自己调用（e.g. `mdex = [markdown: markdown] |> MDEx.new() |> MDExMermaid.attach()`）
  - [ ] 站内资源
    - 同时涉及到了 `hana_shirabe` 以及 `hana_shirabe_web` 两个应用，一个负责与领域模型对接，一个负责界面渲染相关（当前的解决方向，本应用定义 callback ，具体的对接业务在那两个应用实现）
  - [x] 网站链接
    - Acfun, Niconico, Tieba, Bilibili, VNDB etc.
  - [ ] Bibliography
    - 可能需要实现 CSL 【工作量巨大】，可选
- 【暂时无法实现】在网页端使用 Quill Delta
  - 与应用本体以及插件无缝衔接
  - 参见 < https://elixirforum.com/t/how-to-connect-quill-with-phoenix/46004 >
  - 因目前还不支持 Quill Delta 向 `%MDEx.Document{}` 的处理，转用 EasyMDE
