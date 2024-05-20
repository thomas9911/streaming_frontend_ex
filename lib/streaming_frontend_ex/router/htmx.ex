defmodule StreamingFrontendEx.Router.Htmx do
  @moduledoc false

  @home_file Application.app_dir(:streaming_frontend_ex, "priv/static/home.html")
  @home File.read!(@home_file)
  @external_resource @home_file

  @headings [:h1, :h2, :h3, :h4, :h5, :h6]

  def home, do: @home

  def render(text) when is_binary(text), do: text

  def render({:text, inner, _opts}) do
    "<div>#{render(inner)}</div>"
  end

  def render({:divider, _, _opts}) do
    "<hr>"
  end

  def render({:division, parent, opts}) do
    class =
      cond do
        Access.get(opts, :block) -> :block
        Access.get(opts, :box) -> :box
        true -> ""
      end

    "<div class=\"#{class}\" id=\"#{parent}\"></div>"
  end

  def render({:preformatted_text, inner, _opts}) do
    "<div><pre>#{render(inner)}</pre></div>"
  end

  def render({:title, {heading, inner}, _opts}) when heading in @headings do
    "<#{heading} class=\"title #{heading_to_bulma_class(heading)}\">#{render(inner)}</#{heading}>"
  end

  def render({:subtitle, {heading, inner}, _opts}) when heading in @headings do
    "<#{heading} class=\"subtitle #{heading_to_bulma_class(heading)}\" >#{render(inner)}</#{heading}>"
  end

  def render({:html, plain_html, _opts}) do
    plain_html
  end

  def render({:markdown_prerendered, html, _opts}) do
    "<div class=\"content\">#{html}</div>"
  end

  def render({:image_binary, binary, opts}) do
    # ratio_attr =
    #   opts
    #   |> Access.get(:ratio)
    #   |> apply_if_something(fn ratio ->
    #     {width, height} =
    #       case {String.split(ratio, "x"), String.split(ratio, ":")} do
    #         {[a, b], _} -> {a, b}
    #         {_, [a, b]} -> {a, b}
    #         _ -> raise "Invalid format"
    #       end

    #     "is-#{width}by#{height}"
    #   end)

    ratio_attr =
      opts
      |> Access.get(:ratio)
      |> apply_if_something(fn {width, height} ->
        "is-#{width}by#{height}"
      end)

    alt_text =
      opts
      |> Access.get(:alt)
      |> apply_if_something(&"alt=\"#{&1}\"")

    """
    <figure class="image #{ratio_attr}">
      <img #{alt_text} src="data:image/png; base64,#{Base.encode64(binary)}" />
    </figure>
    """
  end

  def render({:simple_input, id, _opts}) do
    # """
    # <form
    #   id="#{id}"
    #   onsubmit="event.preventDefault();
    #   window.socket.send(JSON.stringify({
    #     id: event.target.id, value: {
    #       name: event.target[0].name,
    #       value: event.target[0].value
    #   }}))"
    # >
    #   <input type="text" name="userInput" />
    # </form>
    # """
    """
    <form
      id="#{id}"
      onsubmit="event.preventDefault();
      window.socket.send(JSON.stringify({
        id: event.target.id, value: event.target[0].value}))"
    >
      <input class="input" type="text" name="userInput" />
    </form>
    """
  end

  defp apply_if_something(nil, _), do: ""
  defp apply_if_something(value, formatter), do: formatter.(value)

  defp heading_to_bulma_class(heading) do
    case heading do
      :h1 -> "is-1"
      :h2 -> "is-2"
      :h3 -> "is-3"
      :h4 -> "is-4"
      :h5 -> "is-5"
      :h6 -> "is-6"
    end
  end
end
