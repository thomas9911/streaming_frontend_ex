defmodule StreamingFrontendEx.Router.StreamingServer do
  @moduledoc false

  alias StreamingFrontendEx.AppDefinition
  alias StreamingFrontendEx.Router.Htmx

  defmodule Message do
    @moduledoc false
    @derive Jason.Encoder
    defstruct [:html, :parent]
  end

  def registry do
    StreamingFrontendEx.WebSocketRegistry
  end

  def channel_name do
    "websocket_conn"
  end

  def dispatch(callback) do
    Registry.dispatch(registry(), channel_name(), fn entries ->
      Enum.each(entries, callback)
    end)
  end

  def init(options) do
    Registry.register(registry(), channel_name(), {})
    send(self(), :startup)

    {:ok, options}
  end

  def terminate(_, state) do
    Registry.unregister(registry(), channel_name())

    {:ok, state}
  end

  def handle_in({"ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end

  def handle_info({_, _, _} = html_item, state) do
    message = html_item_to_message(html_item)
    {:push, {:text, Jason.encode!(message)}, state}
  end

  def handle_info(:startup, state) do
    # data = Enum.map(AppDefinition.list(), fn item -> {:text, Htmx.render(item)} end)
    send(self(), :paginate)
    {:ok, Map.put(state, :index, 0)}
  end

  def handle_info(:paginate, %{index: index} = state) do
    # data = Enum.map(AppDefinition.list(), fn item -> {:text, Htmx.render(item)} end)
    case AppDefinition.get(index) do
      {:ok, html_item} ->
        send(self(), :paginate)
        message = html_item_to_message(html_item)
        {:push, {:text, Jason.encode!(message)}, Map.put(state, :index, index + 1)}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(data, state) do
    IO.inspect(data, label: "unhandled event")
    {:push, {:text, "hallo"}, state}
  end

  defp html_item_to_message(item) do
    %Message{html: Htmx.render(item), parent: parent_to_id(item)}
  end

  defp parent_to_id({_, _, options}) do
    Access.get(options, :parent)
  end
end
