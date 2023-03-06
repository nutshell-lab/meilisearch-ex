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

      name: "Meilisearch-Ex",
      organization: "nutshell_lab",
      licenses: ["MIT"],
      source_url: "https://github.com/nutshell-lab/meilisearch-ex",
      homepage_url: "https://github.com/nutshell-lab/meilisearch-ex",
      docs: [
        main: "Meilisearch-Ex",
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
      {:jason, ">= 1.0.0"},
      {:ecto, "~> 3.9"},
      {:finch, "~> 0.14.0", only: [:dev, :test]},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},
      {:excontainers, "~> 0.3.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
