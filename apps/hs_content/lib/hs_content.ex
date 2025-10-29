defmodule HSContent do
  @moduledoc """
  应用端点。

  目前考虑三种形式的内容格式：

  * Markdown(In database), `domain`
  * Markdown(Export), `link`
  * HTML(Apperance with some link or components), `html`

  因为涉及的数据的独特性（主要包括），所以需要考虑插件。

  一般来讲，一个插件要考虑五个 callback ，分别是：

  * 识别 domain_content
  * 识别 export_content
  * 将对象变为 domain_content
  * 将对象变为 export_content
  * 将对象变为 html_component
  """

  @type t :: %__MODULE__{
          document: MDEx.Document.t(),
          derive: :outsite | :domain,
          plugins: list(module())
        }

  defstruct [:document, :derive, :plugins]

  @doc """
  从仓库格式（纯 Markdown 字符串）创建一个 HSContent 实例。
  """
  @spec from_domain(binary(), list(module()), any()) :: t()
  def from_domain(markdown_string, plugins \\ [], _opts \\ []) do
    %__MODULE__{
      document: MDEx.parse_document!(markdown_string),
      derive: :domain,
      plugins: plugins
    }
  end

  def from_export_markdown(markdown_string, plugins \\ [], _opts \\ []) do
    %__MODULE__{
      document: MDEx.parse_document!(markdown_string),
      derive: :outsite,
      plugins: plugins
    }
  end

  @doc """
  将内容转换为用于 Web 渲染的 HTML 字符串。
  """
  @spec to_html(t(), any()) :: binary()
  def to_html(%__MODULE__{document: doc, derive: derive, plugins: plugins}, _opts \\ []) do
    doc
    |> apply_plugins(derive, :html, plugins)
    |> MDEx.to_html!(
      # 在这里放置通用的 MDEx 渲染选项
      extension: [strikethrough: true, table: true, tasklist: true],
      syntax_highlight: [formatter: {:html_inline, theme: "github_dark"}]
    )
  end

  @doc """
  将内容转换为用于导出的 Markdown 字符串。

  它会按顺序应用所有插件的 `:export` 转换逻辑。
  """
  @spec to_export_markdown(t(), any()) :: binary()
  def to_export_markdown(%__MODULE__{document: doc, derive: derive, plugins: plugins}, _opts \\ []) do
    doc
    |> apply_plugins(derive, :export, plugins)
    |> MDEx.to_markdown!()
  end

  @doc """
  将内容转换回仓库格式的 Markdown 字符串。
  """
  @spec to_domain_markdown(t(), any()) :: binary()
  def to_domain_markdown(%__MODULE__{document: doc, derive: derive, plugins: plugins}, _opts \\ []) do
    doc
    |> apply_plugins(derive, :domain, plugins)
    |> MDEx.to_markdown!()
  end

  # 管道的核心：按顺序应用每个插件的 transform 函数
  defp apply_plugins(initial_doc, deserialization_env, serialization_env, plugins) do
    Enum.reduce(plugins, initial_doc, fn plugin_module, current_doc ->
      # 调用每个插件的 transform/2 函数
      case deserialization_env do
        :export -> current_doc
        |> plugin_module.normalize()
        |> plugin_module.transform(serialization_env)

        _ -> current_doc
        |> plugin_module.transform(serialization_env)
      end
    end)
  end
end
