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

  def add_text(input, _opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:text, input}})
  end

  def add_preformatted_text(input, _opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:preformatted_text, input}})
  end

  def add_title(input, opts \\ []) do
    heading = Keyword.get(opts, :heading, :h1)
    GenServer.cast(__MODULE__, {:add, {:title, {heading, input}}})
  end

  def add_subtitle(input, opts \\ []) do
    heading = Keyword.get(opts, :heading, :h1)
    GenServer.cast(__MODULE__, {:add, {:subtitle, {heading, input}}})
  end

  def add_divider(_opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:divider, []}})
  end

  def add_html(input, _opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:html, input}})
  end

  def add_markdown(input, _opts \\ []) do
    GenServer.cast(__MODULE__, {:add, {:markdown_prerendered, Earmark.as_html!(input, compact_output: true)}})
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

  def handle_cast({:add, tag}, state) do
    StreamingServer.dispatch(fn {pid, _} ->
      send(pid, tag)
    end)

    new_state = [tag | state]
    {:noreply, new_state}
  end
end
