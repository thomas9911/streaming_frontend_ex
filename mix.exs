defmodule StreamingFrontendEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :streaming_frontend_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "StreamingFrontendEx"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:styler, "~> 0.11.9", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:mix_readme, "~> 0.2.1", only: :dev, runtime: false},
      {:bandit, "~> 1.0"},
      {:websock_adapter, "~> 0.5.6"},
      {:plug, "~> 1.15.3"},
      {:earmark, "~> 1.4.46"},
      {:stream_split, "~> 0.1.7"},
      {:jason, "~> 1.4.1"}
    ]
  end
end
