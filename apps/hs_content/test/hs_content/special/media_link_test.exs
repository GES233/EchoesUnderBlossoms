defmodule HSContent.Special.MediaLinkTest do
  use ExUnit.Case

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

    test "等我实现了别的网站就放在这里，猴子岛和劈里啪啦不对付"
    # 参见 https://moegirl.icu/Bilibili/争议和影响#与AcFun的纠纷

    test "B站AV号", %{bilibili_av: avid}

    test "B站BV号", %{bilibili_bv: bvid}

    test "B站AV号带分P", %{bilibili_av: avid}

    test "B站BV号带分P", %{bilibili_bv: bvid}
  end

  describe "测试 transform/2" do
    test "测试链接转换（形如 `[[]]` 的链接）"

    test "测试向嵌入式媒体的链接转换（形如 `![[]]` 的链接）"

    test "测试别名功能（形如 `[[...|Your Aliases]]` 的链接）"
  end

  describe "测试 normalize/1" do
    test "测试将普通链接转换"

    test "测试嵌入式媒体链接无法被转换"
  end
end
