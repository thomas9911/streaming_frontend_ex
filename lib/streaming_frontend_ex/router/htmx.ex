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

  def render({:image_binary, binary, _opts}) do
    """
    <figure class="image is-128x128">
      <img src="data:image/png; base64,#{Base.encode64(binary)}" />
    </figure>
    """
  end

  # defp parent_to_id(options) do
  #   case Access.fetch(options, :parent) do
  #     parent -> "id=\"#{parent}\""
  #     _ -> ""
  #   end
  # end

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
