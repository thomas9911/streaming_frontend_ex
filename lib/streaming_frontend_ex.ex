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
        )
      ] ++ app_task

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Run an app from a script. See module doc.

  This function will hang until a signal to stop is send
  """
  def app(start_link_options \\ [], app_defintion_function) do
    {:ok, process_pid} = start_link(start_link_options)

    try do
      app_defintion_function.()

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

  defdelegate image(image_data, opts \\ []), to: AppDefinition, as: :add_image
end
