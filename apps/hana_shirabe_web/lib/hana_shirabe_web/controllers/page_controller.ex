defmodule HanaShirabeWeb.PageController do
  use HanaShirabeWeb, :controller

  import HanaShirabeWeb.Helpers.Render

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

    > 来一段中文的引文。

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

  # ==== STATIC PAGE ==== #

  # 如果这些页面太多可以在这里列到一起去
  @page_dir "apps/hana_shirabe_web/priv/pages/"
  @static_page_and_meta %{
    about:
      {@page_dir <> "about",
       %{"en" => :mannual_checked, "ja" => :unavailable, "zh_Hans" => :mannual_checked}}
  }

  def render_static_page(conn, {path, locales}) do
    render(conn, :page, render_static_assigns(path, locales))
  end

  def about(conn, _params), do: render_static_page(conn, @static_page_and_meta[:about])
end
