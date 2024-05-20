defmodule StreamingFrontendEx.AppDefinition do
  @moduledoc false
  use GenServer

  alias StreamingFrontendEx.Router.StreamingServer

  defmodule State do
    @moduledoc false
    defstruct items: [], dynamic_only: false
  end

  def init(_init_arg) do
    {:ok, %State{items: []}}
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

  def add_image(image_input, opts \\ []) do
    updated_opts =
      case Access.fetch(opts, :ratio) do
        {:ok, ratio} ->
          {width, height} =
            case {String.split(ratio, "x"), String.split(ratio, ":")} do
              {[a, b], _} -> {a, b}
              {_, [a, b]} -> {a, b}
              _ -> raise "Invalid format"
            end

          Keyword.put(opts, :ratio, {width, height})

        _ ->
          opts
      end

    binary =
      case image_input do
        {:path, path} -> File.read!(path)
        binary -> binary
      end

    GenServer.cast(__MODULE__, {:add, {:image_binary, binary, updated_opts}})
  end

  def add_lazy_block(opts \\ [], callback) do
    GenServer.cast(__MODULE__, {:add, {:lazy_block, callback, opts}})
  end

  def add_simple_input(id, opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:simple_input, id, opts}})
  end

  ## Admin functions

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def get(index) do
    GenServer.call(__MODULE__, {:get, index})
  end

  def halt do
    GenServer.call(__MODULE__, :halt)
  end

  def continue do
    GenServer.call(__MODULE__, :continue)
  end

  ## Implementations

  def handle_call(:list, _, %State{items: items} = state) do
    {:reply, Enum.reverse(items), state}
  end

  def handle_call({:get, index}, _, %State{items: items} = state) do
    reversed_index = length(items) - (index + 1)

    if reversed_index >= 0 do
      {:reply, {:ok, Enum.at(items, reversed_index)}, state}
    else
      {:reply, :error, state}
    end
  end

  def handle_call(:halt, _, state) do
    {:reply, :ok, %State{state | dynamic_only: true}}
  end

  def handle_call(:continue, _, state) do
    {:reply, :ok, %State{state | dynamic_only: false}}
  end

  def handle_cast({:add, item}, %State{items: items, dynamic_only: dynamic_only} = state) do
    StreamingServer.dispatch(fn {pid, _} ->
      send(pid, item)
    end)

    new_state =
      if dynamic_only do
        state
      else
        new_items = [item | items]
        %State{state | items: new_items}
      end

    {:noreply, new_state}
  end

  defp generate_parent_id do
    32
    |> :rand.bytes()
    |> Base.encode32(padding: false, case: :lower)
  end
end
