# StreamingFrontendEx

## Installation

```elixir
def deps do
  [
    {:streaming_frontend_ex, "~> 0.1.0"}
  ]
end
```

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



## TODO think of a better name? 
