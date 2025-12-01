defmodule HanaShirabeWeb.Helpers.Render do
  @moduledoc """
  用于 Markdown 渲染。
  """

  # 因为该功能的复用性从 PageController 中剥离出来。

  @type locale_status :: :mannual_checked | :machine_translated | :unavailable
  @type locales :: %{optional(String.t()) => locale_status}

  @spec render_static_assigns(String.t(), locales()) :: keyword()
  def render_static_assigns(path, locales) do
    locale = Gettext.get_locale()

    chosen_locale =
      cond do
        Map.get(locales, locale) in [:mannual_checked, :machine_translated] ->
          locale

        true ->
          locales
          |> Enum.find_value(fn {loc, status} ->
            if status == :mannual_checked, do: loc, else: nil
          end) || Application.fetch_env!(:gettext, :default_locale)
      end

    machine_translate? =
      case Map.get(locales, chosen_locale) do
        :machine_translated -> true
        _ -> false
      end

    chosen_locale? = locale == chosen_locale

    html =
      path
      |> Path.join("#{chosen_locale}.md")
      |> File.read!()
      |> HSContent.from_domain()
      |> HSContent.to_html()

    [
      html: html,
      page_title: {:role, "About"},
      machine_translate: machine_translate?,
      chosen_locale: !chosen_locale?
    ]
  end
end
