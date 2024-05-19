defmodule StreamingFrontendEx.Router do
  use Plug.Router

  alias StreamingFrontendEx.Router.Htmx
  alias StreamingFrontendEx.Router.StreamingServer

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_html(conn, Htmx.home())
  end

  get "/websocket" do
    conn
    |> WebSockAdapter.upgrade(StreamingServer, %{}, timeout: 60_000)
    |> halt()
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp send_html(conn, html) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
end
