defmodule Meilisearch.MixProject do
  use Mix.Project

  @version "1.0.0"
  @github_url "https://github.com/nutshell-lab/meilisearch-ex"

  def project do
    [
      app: :meilisearch,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
      description: description(),
      package: package(),
      docs: [
        main: "readme",
        name: "meilisearch_ex",
        source_ref: "v#{@version}",
        source_url: @github_url,
        extras: ["README.md"]
      ]
    ]
  end

  defp description do
    "An unofficial Meilisearch client based on Tesla HTTP client."
  end

  defp package do
    [
      name: "meilisearch_ex-ex",
      licenses: ["MIT"],
      links: %{
        "Meilisearch" => "https://www.meilisearch.com/",
        "Meilisearch documentation" => "https://docs.meilisearch.com/"
      }
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
