defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  # 如果这些页面太多可以在这里列到一起去
  # @page_dir "apps/hana_shirabe_web/priv/page/"
  # @static_page_and_meta %{
  #   about: {@page_dir <> "license", %{"en" => :mannual_checked, "ja" => :not_implemented, "zh_Hans" => :mannual_checked}},
  # }

  def home(conn, _params) do
    render(conn, :home)
  end

  def show(conn, _params) do
    render(conn, :show, page_title: {:role, "页面展示"})
  end

  def license(conn, _params) do
    render(conn, :license)
  end

  def render_static_page(conn, {path, locales}) do
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

    markdown =
      path
      |> Path.join("#{chosen_locale}.md")
      |> File.read!()
      |> HSContent.from_domain()
      |> HSContent.to_html()

    render(conn, :static_page, markdown: markdown, machine_translate: machine_translate?)
  end

  # TODO: implement a `for` macro to automatically mount these functions.
  # defmacro def_page(site_and_data) do
  #   Enum.map(site_and_data, fn {site, data} ->
  #     quote bind_quoted: [site: site, data: data] do
  #       def unquote(site)(conn, unquote(status)) do
  #         render_static_page(conn, unquote(status))
  #       end
  #     end
  #   end)
  # end

  # defmacro def_page_route(site_and_data) do
  #   Enum.map(site_and_data, fn {site, data} ->
  #     quote do
  #       get("/" <> unquote(site |> Atom.to_string()))
  #     end
  #   end)
  # end

  # def_page @static_page_and_meta
end
