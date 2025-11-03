defmodule HSContentTest do
  use ExUnit.Case

  describe "创建 HSContent 实例" do
    test "通过 from_domain/3 创建实例" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_domain(markdown)

      assert hs_content.derive == :domain
    end

    test "通过 from_export_markdown/3 创建实例" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_export_markdown(markdown)

      assert hs_content.derive == :export
    end

    test "创建成功的 :document 字段属于 %MDEx.Document{}" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_domain(markdown)

      assert %MDEx.Document{} = hs_content.document
    end
  end

  describe "HSContent 实例可渲染为一系列内容" do
    test "to_html/2 方法返回 HTML 字符串" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_domain(markdown)

      html_output = HSContent.to_html(hs_content)

      assert String.contains?(html_output, "<h1>标题</h1>")
      assert String.contains?(html_output, "<p>这是一些内容。</p>")
    end

    test "to_export_markdown/2 方法返回 Markdown 字符串" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_domain(markdown)

      export_markdown = HSContent.to_export_markdown(hs_content)

      assert String.contains?(export_markdown, "# 标题")
      assert String.contains?(export_markdown, "这是一些内容。")
    end

    # TODO: 上下后续可以重构为一个测试，两类 Markdown 最大的差别源于插件的差异化设置
    test "to_domain_markdown/2 方法返回 Markdown 字符串" do
      markdown = "# 标题\n\n这是一些内容。"
      hs_content = HSContent.from_export_markdown(markdown)

      domain_markdown = HSContent.to_domain_markdown(hs_content)

      assert String.contains?(domain_markdown, "# 标题")
      assert String.contains?(domain_markdown, "这是一些内容。")
    end
  end

  ## 在这里定义一系列的插件，并且进行测试
end
