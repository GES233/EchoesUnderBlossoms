defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  # 如果这些页面太多可以在这里列到一起去
  @page_dir "apps/hana_shirabe_web/priv/pages/"
  @static_page_and_meta %{
    about:
      {@page_dir <> "about",
       %{"en" => :mannual_checked, "ja" => :not_implemented, "zh_Hans" => :mannual_checked}}
  }

  def home(conn, _params) do
    render(conn, :home)
  end

  def show(conn, _params) do
    """
    # 2333

    ## Lorem ipsum

    > Lorem ipsum dolor sit amet consectetur adipisicing elit. Impedit obcaecati
    > temporibus delectus et eaque non enim, consequatur illum velit sapiente
    > molestiae soluta voluptatibus omnis quasi dolores maxime officiis at vero!

    **Lorem ipsum**, dolor sit amet consectetur adipisicing elit. _Aut dignissimos
    quasi pariatur nobis ipsa ullam!_ Commodi modi, saepe eveniet soluta numquam
    quasi ducimus, corrupti architecto distinctio dignissimos alias nesciunt
    doloribus?

    ## 中文版本

    你有这么告诉运转的机械进入中国记住我给出的原理小的时候。就是研发人……

    全民制作人们大家好，我是个人练习两年半的个人练习生…

    - 🐔
      - `2.5`
      - *Ctrl*
    - 只因

    ## 代码

    Powered by [MDEx](https://github.com/leandrocp/mdex).

    ```c
    #include <stdio.h>

    int main () {
        printf("Hello World!");

        return 0;
    }
    ```

    ```elixir
    receive do
      {:sended, msg} -> IO.puts msg
    end
    ```
    """
    |> HSContent.from_domain()
    |> HSContent.to_html()
    |> Phoenix.HTML.raw()
    |> then(&render(conn, :show, page_title: {:role, "页面展示"}, content: &1))
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

    render(conn, :page,
      markdown: markdown,
      page_title: {:role, "About"},
      machine_translate: !machine_translate?
    )
  end

  def about(conn, _params), do: render_static_page(conn, @static_page_and_meta[:about])

  # TODO: implement a `for` macro to automatically mount these functions.
  # defmacro def_page(site_and_data) do
  #   Enum.map(site_and_data, fn {site, data} ->
  #     quote bind_quoted: [site: site, data: data] do
  #       def unquote(site)(conn, _params) do
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
end
