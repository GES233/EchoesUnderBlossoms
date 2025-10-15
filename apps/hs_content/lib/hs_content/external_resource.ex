defmodule HSContent.ExternalResource do
  @moduledoc """
  需要外部函数进行操作的外部资源。
  """
  @type t :: %__MODULE__{
    mod: module(),
    values: struct() | map(),
  }
  defstruct [:mod, :values]
end
