defmodule Meilisearch.MixProject do
  use Mix.Project

  def project do
    [
      app: :meilisearch,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
      docs: [
        main: "Meilisearch-ex",
        extras: ["README.md"]
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
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.16"},
      {:jason, ">= 1.0.0"},
      {:ecto, "~> 3.9"},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},
      {:excontainers, "~> 0.3.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
