defmodule StreamingFrontendEx.AppDefinition do
  @moduledoc false
  use GenServer

  alias StreamingFrontendEx.Router.StreamingServer

  def init(_init_arg) do
    {:ok, []}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## Commands

  def add_text(input, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:text, input, opts}})
  end

  def add_preformatted_text(input, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:preformatted_text, input, opts}})
  end

  def add_title(input, opts \\ []) do
    heading = Keyword.get(opts, :heading, :h1)
    GenServer.cast(__MODULE__, {:add, {:title, {heading, input}, opts}})
  end

  def add_subtitle(input, opts \\ []) do
    heading = Keyword.get(opts, :heading, :h1)
    GenServer.cast(__MODULE__, {:add, {:subtitle, {heading, input}, opts}})
  end

  def add_divider(opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:divider, [], opts}})
  end

  def add_division(opts \\ []) do
    parent =
      case Keyword.fetch(opts, :parent) do
        {:ok, parent} -> parent
        _ -> generate_parent_id()
      end

    GenServer.cast(__MODULE__, {:add, {:division, parent, opts}})
    parent
  end

  def add_html(input, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:html, input, opts}})
  end

  def add_markdown(input, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:markdown_prerendered, Earmark.as_html!(input, compact_output: true), opts}})
  end

  def add_image(binary, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:image_binary, binary, opts}})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def get(index) do
    GenServer.call(__MODULE__, {:get, index})
  end

  ## Implementations

  def handle_call(:list, _, state) do
    {:reply, Enum.reverse(state), state}
  end

  def handle_call({:get, index}, _, state) do
    reversed_index = length(state) - (index + 1)

    if reversed_index >= 0 do
      {:reply, {:ok, Enum.at(state, reversed_index)}, state}
    else
      {:reply, :error, state}
    end
  end

  def handle_cast({:add, item}, state) do
    StreamingServer.dispatch(fn {pid, _} ->
      send(pid, item)
    end)

    new_state = [item | state]
    {:noreply, new_state}
  end

  defp generate_parent_id do
    32
    |> :rand.bytes()
    |> Base.encode32(padding: false, case: :lower)
  end
end
