defmodule HanaShirabeWeb.Gettext do
  @moduledoc """
  一个提供基于 gettext API 的国际化模块。

  通过使用 [Gettext](https://hexdocs.pm/gettext) ，你在应用中声明的翻译会被模块编译。
  为使用这个 Gettext 后端模块，需调用 `use Gettext` 并将其作为一个选项传递：

      use Gettext, backend: HanaShirabeWeb.Gettext

      # 普通翻译
      gettext("Here is the string to translate")

      # 复数（是 plural 不是 complex number）翻译
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # 基于领域的翻译
      dgettext("errors", "Here is the error message to translate")

      # 基于语境的翻译
      # 参考上面的 plural / complex number 但汉语同义的差异
      # 噢，Elixir 的 Gettext 不支持，那没事了

  参见 [Gettext Docs](https://hexdocs.pm/gettext) 以了解更多。
  """
  use Gettext.Backend, otp_app: :hana_shirabe_web
end
