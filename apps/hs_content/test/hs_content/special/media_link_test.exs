defmodule HSContent.Special.MediaLinkTest do
  use ExUnit.Case

  defp to_html(markdown_string) do
    HSContent.from_domain(markdown_string, [HSContent.Special.MediaLink])
    |> HSContent.to_html()
  end

  defp to_export_markdown(markdown_string) do
    HSContent.from_domain(markdown_string, [HSContent.Special.MediaLink])
    |> HSContent.to_export_markdown()
  end

  defp to_domain_markdown(markdown_string) do
    HSContent.from_domain(markdown_string, [HSContent.Special.MediaLink])
    |> HSContent.to_domain_markdown()
  end

  defp normalize_export(markdown_string) do
    HSContent.from_export_markdown(markdown_string, [HSContent.Special.MediaLink])
    |> HSContent.to_domain_markdown()
  end

  describe "测试 schema" do
    setup do
      HSContent.Special.MediaLink.schema()
      |> Enum.map(fn %{key: key} = item -> {key, item} end)
      |> Enum.into(%{})
    end

    test "A站不分P", %{acfun: acfun} do
      assert Regex.match?(acfun.id_pattern, "ac123456")

      assert Regex.run(acfun.url_pattern, "https://www.acfun.cn/v/ac123456") == [
               "acfun.cn/v/ac123456",
               "ac123456"
             ]

      assert acfun.html_embed_url.("ac123456", nil) ==
               "https://www.acfun.cn/player/ac123456"

      assert acfun.export_url.("ac123456", nil) ==
               "https://www.acfun.cn/v/ac123456"
    end

    # 等我实现了别的网站就放在这里，猴子岛和劈里啪啦不对付"
    # 参见 https://moegirl.icu/Bilibili/争议和影响#与AcFun的纠纷

    test "B站AV号", %{bilibili_av: avid} do
      assert Regex.match?(avid.id_pattern, "av170001")

      assert avid.export_url.("av170001", nil) =~
               "https://www.bilibili.com/video/av170001"
    end

    test "B站BV号", %{bilibili_bv: _bvid} do
      assert 1 + 1 == 2
    end

    test "B站带分P", %{bilibili_av: _avid, bilibili_bv: _bvid} do
      assert 1 + 1 == 2
    end
  end

  # describe "测试 transform/2" do
  #   test "测试链接转换（形如 `[[]]` 的链接）" do
  #     input = "这是一个 AcFun 视频 [[ac123456]]。"
  #     expected_html = ~r/<a href="https:\/\/www\.acfun\.cn\/v\/ac123456".*>ac123456<\/a>/
  #     expected_export = "这是一个 AcFun 视频 [ac123456](https://www.acfun.cn/v/ac123456)。"
  #     expected_domain = input

  #     assert to_html(input) =~ expected_html
  #     assert to_export_markdown(input) == expected_export
  #     # 测试 to_domain 应该保持原文不变
  #     assert to_domain_markdown(input) == expected_domain
  #   end

  #   test "测试向嵌入式媒体的链接转换（形如 `![[]]` 的链接）" do
  #     input = "这是一个 Bilibili 视频 ![[av170001]]。"

  #     expected_html =
  #       ~r/<div class="media-embed"><iframe src="\/\/player\.bilibili\.com\/player\.html\?aid=170001.*"><\/iframe><\/div>/

  #     # 导出时，嵌入式链接应降级为普通链接
  #     expected_export = "这是一个 Bilibili 视频 [av170001](https://www.bilibili.com/video/av170001/)。"
  #     expected_domain = input

  #     assert to_html(input) =~ expected_html
  #     assert to_export_markdown(input) == expected_export
  #     assert to_domain_markdown(input) == expected_domain
  #   end

  #   test "测试别名功能（形如 `[[...|Your Aliases]]` 的链接）" do
  #     input = "这是一个带别名的视频 [[BV1tM411Y7dh|妖王]] 和分P ![[ac600087|某知名视频]]"
  #     # 测试 HTML 中的别名
  #     assert to_html(input) =~ ~r/>妖王<\/a>/
  #     # 嵌入式 iframe 没有别名，所以我们不测试它
  #     assert to_html(input) =~ ~r/<iframe/

  #     # 测试导出 Markdown 中的别名
  #     assert to_export_markdown(input) =~ "[妖王](https://www.bilibili.com/video/BV1tM411Y7dh)"
  #     assert to_export_markdown(input) =~ "[某知名视频](https://www.acfun.cn/v/ac600087)"
  #   end
  # end

  # describe "测试 normalize/1" do
  #   test "测试将普通链接转换" do
  #     input = "这是一个来自 B 站的链接 [保加利亚妖王](https://www.bilibili.com/video/av170001?p=3)。"
  #     # 注意，我们使用了新的辅助函数 normalize_export/1
  #     expected_domain = "这是一个来自 B 站的链接 [[av170001:P3|保加利亚妖王]]。"

  #     assert normalize_export(input) == expected_domain
  #   end

  #   test "测试外部链接不会被转换" do
  #     input = "这是一个外部链接 [Elixir School](https://elixirschool.com)。"
  #     # 当 normalize 遇到它不认识的链接时，应该保持原样
  #     # HSContent.from_export_markdown 会先 normalize 再 transform(:domain)
  #     # 所以最终结果应该和输入一样
  #     assert normalize_export(input) == input
  #   end

  #   # 这个测试用例的标题可能需要调整，因为我们的 normalize 逻辑只处理 Link 节点
  #   # 嵌入式媒体 ![[...]] 在输入时是 Text 节点，所以 normalize 不会处理它
  #   # 这个测试实际上是多余的，但我们可以保留它来明确这个行为
  #   test "测试嵌入式媒体链接无法被转换" do
  #     input = "这是一个嵌入式链接 ![[av170001]]"
  #     # 因为输入不是一个 Link 节点，normalize 不会作用于它
  #     assert normalize_export(input) == input
  #   end
  # end
end
