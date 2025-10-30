defmodule HSContent.Special.MediaLink do
  @moduledoc """
  媒体链接，可以使用形如 `[[...]]` 的 WikiLink 语法。

  目前支持的网站：

  - Acfun
  - Bilibili (AV 号和 BV 号)

  需要注意的是，目前不支持将嵌入式媒体渲染为 Markdown 导出格式，因为大多数 Markdown
  渲染器并不支持嵌入式媒体。

  """

  @wikilink_regex ~r/(!?)\[\[([a-zA-Z0-9]+)(?::[pP](\d+))?(?:\|([^\]]+))?\]\]/

  @doc """
  定义了支持的媒体链接来源的网站 schema 列表。

  所需要的键值：

  * `:key` - 网站的唯一标识符
  * `:id_pattern` - 用于匹配媒体 ID 的正则表达式
  * `:url_pattern` - 用于匹配媒体链接 URL 的正则表达式
  * `:html_embed_url` - 一个函数，接受媒体 ID 和分 P 参数，返回用于嵌入的
    HTML URL（若没有和 `:export_url` 一致即可）
  * `:export_url` - 一个函数，接受媒体 ID 和分 P 参数，返回用于导出的标准链接 URL
  """
  def schema,
    do: [
      %{
        key: :acfun,
        id_pattern: ~r/^ac\d+$/i,
        url_pattern: ~r/acfun\.cn\/v\/(ac\d+)/i,
        html_embed_url: fn id, _part ->
          "https://www.acfun.cn/player/ac#{String.trim_leading(id, "ac")}"
        end,
        export_url: fn id, _part -> "https://www.acfun.cn/v/#{id}" end
      },
      %{
        key: :bilibili_av,
        id_pattern: ~r/^av\d+$/i,
        url_pattern: ~r/bilibili\.com\/video\/(av\d+)/i,
        html_embed_url: fn id, part ->
          "//player.bilibili.com/player.html?aid=#{String.trim_leading(id, "av")}&page=#{part || 1}&high_quality=1&danmaku=0"
        end,
        export_url: fn id, part ->
          page_query = if String.length(part) > 0, do: "?p=#{part}", else: ""
          "https://www.bilibili.com/video/#{id}#{page_query}"
        end
      },
      %{
        key: :bilibili_bv,
        id_pattern: ~r/^BV[a-zA-Z0-9]+$/i,
        url_pattern: ~r/bilibili\.com\/video\/(BV[a-zA-Z0-9]+)/i,
        html_embed_url: fn id, part ->
          "//player.bilibili.com/player.html?bvid=#{id}&page=#{part || 1}&high_quality=1&danmaku=0"
        end,
        export_url: fn id, part ->
          page_query = if String.length(part) > 0, do: "?p=#{part}", else: ""
          "https://www.bilibili.com/video/#{id}#{page_query}"
        end
      }
    ]

  use HSContent.SpecialItem

  @impl true
  def transform(document, serialization_env) do
    MDEx.traverse_and_update(document, fn
      %MDEx.Text{literal: text} = node ->
        # 使用 Regex.replace/4 动态替换所有匹配项
        new_literal =
          Regex.replace(
            @wikilink_regex,
            text,
            &transformer(&1, &2, &3, &4, &5, serialization_env)
          )

        %{node | literal: new_literal}

      node ->
        node
    end)
  end

  @impl true
  def normalize(document) do
    MDEx.traverse_and_update(document, fn
      # 我们只关心链接节点
      %MDEx.Link{url: dest, nodes: [%MDEx.Text{literal: link_alias}]} = node ->
        # 尝试将 URL 转换回内部格式
        case normalizer(dest, link_alias) do
          {:ok, internal_format} -> %MDEx.Text{literal: internal_format}
          :error -> node
        end

      node ->
        node
    end)
  end

  defp transformer(full_match, embedd_flag, id, part, link_alias, environment) do
    source = Enum.find(schema(), &Regex.match?(&1.id_pattern, id))

    embedd = embedd_flag == "!"

    link_text = if link_alias, do: link_alias, else: id

    if source do
      case environment do
        :html ->
          if embedd do
            ~s(<div class="media-embed"><iframe src="#{source.html_embed_url.(id, part)}" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" sandbox="allow-top-navigation allow-same-origin allow-forms allow-scripts"></iframe></div>)
          else
            ~s(<a href="#{source.export_url.(id, part)}" class="inline-media-link" target="_blank" rel="noopener noreferrer">#{link_text}</a>)
          end

        :export ->
          url = source.export_url.(id, part)

          "[#{link_text}](#{url})"

        :domain ->
          part_segment =
            case part do
              "" -> ""
              _ -> "#{part}"
            end

          alias_segment =
            case link_alias do
              "" -> ""
              _ -> "|#{link_alias}"
            end

          embedd_flag <> "[[" <> id <> part_segment <> alias_segment <> "]]"
      end
    else
      "#{full_match}(Unknown Source)"
    end
  end

  defp normalizer(url, link_alias) do
    source = Enum.find(schema(), &Regex.match?(&1.url_pattern, url))

    if source do
      [_, id] = Regex.run(source.url_pattern, url)
      [_ | part] = Regex.run(~r/[?&]p=(\d+)/, url) || []
      part_str = if part != [], do: ":P#{hd(part)}", else: ""

      alias_str =
        if link_alias != "" and link_alias != source.export_url.(id, hd(part)),
          do: "|#{link_alias}",
          else: ""

      {:ok, "[[#{id}#{part_str}#{alias_str}]]"}
    else
      :error
    end
  end
end
