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

  def handle_in({data, [opcode: :text]}, state) do
    case Jason.decode(data) do
      {:ok, %{"id" => id, "value" => value}} ->
        Registry.dispatch(StreamingFrontendEx.InputRegistry, id, fn entries ->
          for {pid, _} <- entries, do: send(pid, {:input_result, value})
        end)

      _ ->
        :ok
    end

    {:ok, state}
  end

  def handle_info({:lazy_block, _callback, _opts} = item, state) do
    apply_lazy_callback(item, state, nil)
  end

  def handle_info({_, _, _} = html_item, state) do
    IO.inspect(html_item)
    message = html_item_to_message(html_item)
    {:push, {:text, Jason.encode!(message)}, state}
  end

  def handle_info(:startup, state) do
    send(self(), :paginate)
    {:ok, Map.put(state, :index, 0)}
  end

  def handle_info(:paginate, %{index: index} = state) do
    case AppDefinition.get(index) do
      {:ok, {:lazy_block, _callback, _opts} = item} ->
        apply_lazy_callback(item, Map.put(state, :index, index + 1), self())

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

  @spec apply_lazy_callback({:lazy_block, function, list}, map, parent_pid :: pid | nil) :: {:ok, map}
  defp apply_lazy_callback({:lazy_block, callback, _opts}, state, nil) do
    Task.start(callback)
    {:ok, state}
  end

  defp apply_lazy_callback({:lazy_block, callback, _opts}, state, parent_pid) do
    Task.start(fn ->
      AppDefinition.halt()
      callback.()
      AppDefinition.continue()
      send(parent_pid, :paginate)
    end)

    {:ok, state}
  end

  defp html_item_to_message(item) do
    %Message{html: Htmx.render(item), parent: parent_to_id(item)}
  end

  defp parent_to_id({_, _, options}) do
    Access.get(options, :parent)
  end
end
