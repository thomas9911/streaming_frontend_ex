defmodule StreamingFrontendEx do
  @moduledoc """

  ## Getting started

  There are three method of using this library.

  1. Using app with an callback function to define your app

  ```elixir
  Mix.install([:streaming_frontend_ex])

  StreamingFrontendEx.app(fn ->
    StreamingFrontendEx.title("Hello World")
    StreamingFrontendEx.write("This is a nice app!")
  end)
  ```

  This can be run with `elixir <your_file>.exs`.

  2. Using an app with a supervisor

  Add this to your supervisor:

  ```elixr
   children = [
      {StreamingFrontendEx, app: {MyApp, :app, []}}
    ]
  ```

  Here the MyApp module contains an app function that contains the definition.

  for example:

  ```elixir
  defmodule MyApp do
    # using import here so the functions can just be called without the module
    import StreamingFrontendEx, only: [write: 1: title: 1]

    def app do
      title("Hello World")
      write("This is a nice app!")
    end
  end
  ```

  3. Dynamically

  If you want this you don't specific an app parameter in the supervisor and call the functions in your code.

  """

  use Supervisor

  alias StreamingFrontendEx.AppDefinition
  alias StreamingFrontendEx.Router

  @typedoc """
  A type that can be safely ignored
  """
  @type not_special :: any

  def init(arguments) do
    bandit_args =
      arguments
      |> Access.get(:bandit_arguments, [])
      |> Enum.concat(plug: Router)

    app_task =
      case Access.fetch(arguments, :app) do
        {:ok, {module, function, arguments}} ->
          [{Task, fn -> apply(module, function, arguments) end}]

        {:ok, app} when is_function(app, 0) ->
          [{Task, app}]

        _ ->
          []
      end

    children =
      [
        {Bandit, bandit_args},
        AppDefinition,
        Registry.child_spec(
          keys: :duplicate,
          name: StreamingFrontendEx.WebSocketRegistry
        ),
        Registry.child_spec(
          keys: :duplicate,
          name: StreamingFrontendEx.InputRegistry
        )
      ] ++ app_task

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Run an app from a script. See module doc.

  This function will hang until a signal to stop is send
  """
  def app(start_link_options \\ [], app_defintion_function) do
    {open?, start_link_options} = Keyword.pop(start_link_options, :open)
    bandit_arguments = Keyword.get(start_link_options, :bandit_arguments, [])
    bandit_arguments = Keyword.put_new(bandit_arguments, :port, 5845)
    start_link_options = Keyword.put(start_link_options, :bandit_arguments, bandit_arguments)

    {:ok, process_pid} = start_link(start_link_options)

    try do
      app_defintion_function.()

      if open? do
        port = Keyword.fetch!(bandit_arguments, :port)
        open_url("http://localhost:#{port}")
      end

      Process.sleep(:infinity)
    after
      Process.exit(process_pid, :normal)
    end
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Create a new text line
  """
  defdelegate write(text, opts \\ []), to: AppDefinition, as: :add_text

  @doc """
  Create a new preformatted text line
  """
  defdelegate text(text, opts \\ []), to: AppDefinition, as: :add_preformatted_text

  @doc """
  Create a title.

  ## Options

    * `:heading` - [:h1, :h2, :h3, :h4, :h5, :h6]
  """
  defdelegate title(text, opts \\ []), to: AppDefinition, as: :add_title

  @doc """
  Create a subtitle.

  ## Options

    * `:heading` - [:h1, :h2, :h3, :h4, :h5, :h6]
  """
  defdelegate subtitle(text, opts \\ []), to: AppDefinition, as: :add_subtitle

  @doc """
  Create new divider
  """
  defdelegate divider(opts \\ []), to: AppDefinition, as: :add_divider

  @doc """
  Create a division (or <div>)

  This can be used to append content to a specific section.
  """
  defdelegate division(opts \\ []), to: AppDefinition, as: :add_division

  @doc """
  Insert plain html
  """
  defdelegate unsafe_html(html, opts \\ []), to: AppDefinition, as: :add_html

  @doc """
  Insert markdown
  """
  defdelegate markdown(html, opts \\ []), to: AppDefinition, as: :add_markdown

  @doc """
  Insert image

  The input should be the binary data of the image or a tuple with `{:path, "/path/to/image.jpg"}`

  ## Options

    * `:ratio` - binary

      one of: "1x1", "2x1", "3x1","5x4", "4x3", "3x2", "5x3", "16x9"

      or the reverse like: "2x3"

      or using the `:` character like "16:9"

    * `:alt` - The alternative text for the image
  """
  @spec image(binary | {:path, binary}, keyword) :: not_special
  defdelegate image(image_data, opts \\ []), to: AppDefinition, as: :add_image

  @doc """
  Because how this library is written all the statements are executed eagerly.
  Sometimes you dont want this, because you need to fetch data from an api that returns different results
  or like the example below you want to get the current time.

  ```elixir
  StreamingFrontendEx.lazy(fn ->
    Enum.map(0..5, fn _ ->
      Process.sleep(1000)
      StreamingFrontendEx.write("\#{DateTime.utc_now()}")
    end)
  end)

  StreamingFrontendEx.write("Written after lazy has completed")
  ```
  """
  defdelegate lazy(opts \\ [], callback), to: AppDefinition, as: :add_lazy_block

  @doc """
  Get an input from the user via a simple line
  """
  @spec input(keyword) :: binary
  def input(opts \\ []) do
    id = random_id()
    {:ok, _} = Registry.register(StreamingFrontendEx.InputRegistry, id, [])

    AppDefinition.add_simple_input(id, opts)

    receive do
      {:input_result, value} ->
        value
    end
  end

  defp random_id do
    32
    |> :rand.bytes()
    |> Base.encode32(padding: false, case: :lower)
  end

  defp open_url(url) do
    case :os.type() do
      {:unix, :darwin} -> System.cmd("open", [url])
      {:unix, _} -> System.cmd("xdg-open", [url])
      {:win32, _} -> System.cmd("cmd", ["/c", "start", url])
    end
  end
end
