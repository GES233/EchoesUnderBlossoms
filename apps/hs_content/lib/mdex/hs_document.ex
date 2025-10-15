defmodule MDEx.HSDocument do
  # Create custome node.
  # 主要负责实现领域模型

  defmacro __using__(_opts) do
    quote do
      use MDEx.Document.Access
    end
  end
end
