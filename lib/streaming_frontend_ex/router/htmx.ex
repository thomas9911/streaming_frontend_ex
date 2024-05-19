defmodule StreamingFrontendEx.Router.Htmx do
  @moduledoc false

  @home_file Application.app_dir(:streaming_frontend_ex, "priv/static/home.html")
  @home File.read!(@home_file)
  @external_resource @home_file

  @headings [:h1, :h2, :h3, :h4, :h5, :h6]

  def home, do: @home

  def render(text) when is_binary(text), do: text

  def render({:text, inner}) do
    "<div>#{render(inner)}</div>"
  end

  def render({:divider, _}) do
    "<hr>"
  end

  def render({:preformatted_text, inner}) do
    "<div><pre>#{render(inner)}</pre></div>"
  end

  def render({:title, {heading, inner}}) when heading in @headings do
    "<#{heading} class=\"title #{heading_to_bulma_class(heading)}\">#{render(inner)}</#{heading}>"
  end

  def render({:subtitle, {heading, inner}}) when heading in @headings do
    "<#{heading} class=\"subtitle #{heading_to_bulma_class(heading)}\" >#{render(inner)}</#{heading}>"
  end

  def render({:html, plain_html}) do
    plain_html
  end

  def render({:markdown_prerendered, html}) do
    "<div class=\"content\">#{html}</div>"
  end

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
