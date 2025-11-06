# 如果发现没有这个模块的话
# 多半是你写的 heex 出错了
# 参见
# https://elixirforum.com/t/no-root-html-template-defined-for-the-module-does-not-exist/68258
# 所以，在 commit 时，
# 一定要确保你写的 HTML 没什么问题
# 要不然连首页都是个问题
defmodule HanaShirabeWeb.PageHTML do
  @moduledoc """
  这个模块包括了将要被 PageController 渲染的页面。

  可以通过 "page_html/" 目录来查看可用的模板。
  """
  use HanaShirabeWeb, :html

  embed_templates "page_html/*"
end
