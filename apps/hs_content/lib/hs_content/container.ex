defmodule HsContent.Container do
  @moduledoc """
  提供内容的保存与渲染的相关业务。

  其和一般的 Markdown 最大的差异在于其将媒体资源以及脚注与正文进行了分离。
  媒体资源包括特定网站、需要展示的外链或是站内的部分资源。
  """

  @type t :: %__MODULE__{
          title: binary() | nil,
          content: MDEx.Document.t(),
          external_resource: %{atom() => %{term() => any()}} | nil
        }
  defstruct title: nil,
            content: "",
            external_resource: nil

  ## 结构体与文本的互换

  # markdown -> %__MODULE__{}
  def from_markdown(markdown_content, _opts \\ []) do
    %__MODULE__{content: MDEx.parse_document!(markdown_content)}
  end

  # %__MODULE__{} -> markdown
  def to_markdown(content = %__MODULE__{}, _opts \\ [])
      when is_nil(content.title) and is_nil(content.external_resource) do
    content.content |> MDEx.to_markdown!()
  end

  # %__MODULE__{} -> html
  def to_html(content = %__MODULE__{}, _opts \\ [])
      when is_nil(content.title) and is_nil(content.external_resource) do
    content.content |> MDEx.to_html!()
  end
end
