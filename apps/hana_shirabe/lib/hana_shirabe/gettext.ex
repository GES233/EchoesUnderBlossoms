defmodule HanaShirabe.Gettext do
  @moduledoc """
  和 `HanaShirabeWeb.Gettext` 不同的是，这里是针对内部
  （比方说 HanaShirabe.Accounts.MemberNotifier 之类的）
  """
  use Gettext.Backend, otp_app: :hana_shirabe
end
