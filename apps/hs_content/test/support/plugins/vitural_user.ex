defmodule HSContentTest.VituralUser do
  defstruct [:id, :nickname]

  ## 以下部分抄的文档
  @behaviour HSContent.SpecialItem

  @impl true
  def transform(doc, env) do
    MDEx.traverse_and_update(document, fn
      %MDEx.Text{literal: text} = node when "@user:" in text ->
        new_literal = replace_placeholders(text, environment)
        %{node | literal: new_literal}

      node ->
        node
    end)
  end

  @impl true
  def normalize(doc) do
    MDEx.traverse_and_update(document, fn
      %MDEx.Link{url: dest, title: _title} = node ->
        case Regex.run(~r|^/user/(\d+)|, dest) do
          [_, id] ->
            %MDEx.Text{literal: "[[@user:#{id}]]"}

          nil ->
            node
        end

      node ->
        node
    end)
  end

  defp replace_placeholders(text, target) do
    Regex.replace(~r/[[@user:(\d+)]]/, text, fn _full_match, id ->
      case User.gets_user(id) do
        nil ->
          "[[@user:#{id}<Not Found>]]"

        user ->
          case target do
            :html ->
              ~s(<a href="/user/#{user.id}" class="domain-link user-link">#{usre.nickname}</a>)

            :export ->
              "[#{user.nickname}](/user/#{user.id})"

            :domain ->
              "[[@user:#{id}]]"
          end
      end
    end)
  end
end
