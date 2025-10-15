defmodule HSContent.MarkdownRenderTest do
  use ExUnit.Case

  describe "markdown <-> markdown" do
    setup do
      markdown_content = """
      ## 这是标题

      > _少女乐队就是男孩子们的时代少年团。_

      全民制作人们大家好，我是练习时长**两年半**的个人练习生。后面的忘了

          chicken = [:sing, :dance, :rap, :basketball]

      迎面**走来**的你让我如此蠢蠢欲动，这种感觉**我**从未有
      cause I got a crush on you, who you.

      你是我的，我是，你的，谁。
      """

      mdex_content = markdown_content |> MDEx.document!()

      {:ok, [plain_md: markdown_content, mdex_doc: mdex_content]}
    end

    test "markdown -> hs_content", context do
      assert context[:plain_md] |> HSContent.Container.from_markdown() |> is_struct(HSContent.Container)
    end
  end
end
