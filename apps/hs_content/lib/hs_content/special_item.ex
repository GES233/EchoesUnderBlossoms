defmodule HSContent.SpecialItem do
  @moduledoc """
  定义了一个内容转换插件的行为。

  任何希望在 Markdown 内容中处理自定义领域模型的模块都应实现此行为。
  插件的核心是一个 `transform/2` 函数，它接收一个 `MDEx.Document` 和一个
  目标环境，然后返回转换后的 `MDEx.Document`。

  此外还包含一个 `normalize/1` 函数，负责构建领域模型。

  ## Examples

      defmodule UserPlugin do
        @behaviour HSContent.SpecialItem

        @impl true
        def transform(doc, env) do
          MDEx.traverse_and_update(document, fn
            %MDEx.Text{literal: text} = node when "@user:" in text ->
              new_literal = replace_placeholders(text, environment)
            %{node | literal: new_literal}

            node -> node
          end)
        end

        @impl true
        def normalize(doc) do
          MDEx.traverse_and_update(document, fn
            %MDEx.Link{url: dest, title: _title} = node ->
              case Regex.run(~r|^/user/(\\d+)|, dest) do
                [_, id] ->
                  %MDEx.Text{literal: "[[@user:\#{id}]]"}

                nil ->
                  node
              end

            node ->
              node
          end)
        end

        defp replace_placeholders(text, target) do
          Regex.replace(~r/[[@user:(\\d+)]]/, text, fn _full_match, id ->
            case User.gets_user(id) do
              nil ->
              "[[@user:\#{id}<Not Found>]]"

                user ->
                  case target do
                    :html ->
                      # Use phoenix component is better
                      ~s(<a href="/user/\#{user.id}" class="domain-link user-link">\#{usre.nickname}</a>)

                    :export -> "[\#{user.nickname}](/user/\#{user.id})"

                    :domain -> "[[@user:\#{id}]]"
                  end
            end
          end)
        end
      end
  """

  @callback transform(MDEx.Document.t(), HSContent.serialization_env()) ::
              MDEx.Document.t()

  @callback normalize(MDEx.Document.t()) :: MDEx.Document.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour HSContent
      @behaviour HSContent.SpecialItem

      @impl HSContent
      def apply(document, deserialization_env, serialization_env) do
        case deserialization_env do
        :export -> document
        |> normalize()
        |> transform(serialization_env)

        _ -> document
        |> transform(serialization_env)
      end
      end
    end
  end
end
