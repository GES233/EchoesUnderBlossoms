defmodule HanaShirabe.Gettext do
  @moduledoc """
  和 `HanaShirabeWeb.Gettext` 不同的是，这里是针对内部
  （比方说 `HanaShirabe.Accounts.MemberNotifier`
  之类的）【可能会传递给用户的内容】的翻译。

  如果不懂这是啥玩意儿，参见 `HanaShirabeWeb.Gettext`
  的文档说明。
  """
  use Gettext.Backend, otp_app: :hana_shirabe
end
