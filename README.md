<p align="center">
  <img src="https://raw.githubusercontent.com/meilisearch/integration-guides/main/assets/logos/meilisearch_elixir.svg" alt="Meilisearch-JavaScript" width="200" height="200" />
</p>

<h1 align="center">Meilisearch Elixir</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/meilisearch">Meilisearch</a> |
  <a href="https://www.meilisearch.com/docs">Documentation</a> |
  <a href="https://discord.meilisearch.com">Discord</a> |
  <a href="https://roadmap.meilisearch.com/tabs/1-under-consideration">Roadmap</a> |
  <a href="https://www.meilisearch.com">Website</a> |
  <a href="https://www.meilisearch.com/docs/faq">FAQ</a>
</h4>

<p align="center">
  <a href="https://github.com/nutshell-lab/meilisearch-ex/actions/workflows/elixir.yml"><img src="https://github.com/nutshell-lab/meilisearch-ex/actions/workflows/elixir.yml/badge.svg" alt="Tests"></a>
  <a href="https://hex.pm/packages/meilisearch_ex"><img src="https://img.shields.io/hexpm/v/meilisearch_ex" alt="hex.pm version"></a>
  <a href="https://hexdocs.pm/meilisearch_ex"><img src="https://img.shields.io/badge/hexdocs-documentation-ff69b4" alt="hex.pm docs"></a>
  <a href="https://hex.pm/packages/meilisearch_ex"><img src="https://img.shields.io/hexpm/dw/meilisearch_ex" alt="hex.pm downloads"></a>
  <a href="https://coveralls.io/github/nutshell-lab/meilisearch-ex"><img src="https://img.shields.io/coverallsCoverage/github/nutshell-lab/meilisearch-ex" alt="coveralls"></a>
  <a href="https://github.com/nutshell-lab/meilisearch-ex/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
</p>

<p align="center">🧪 The Meilisearch API client written for Elixir</p>

**Meilisearch Ex** is a **unofficial** the Meilisearch API client based on [Finch](https://github.com/sneako/finch) HTTP client wrapped by [Tesla](https://github.com/elixir-tesla/tesla) for Elixir developers.

**Meilisearch** is an open-source search engine. [Learn more about Meilisearch.](https://github.com/meilisearch/meilisearch)

## Table of Contents <!-- omit in toc -->

- [📖 Documentation](#-documentation)
- [🔧 Installation](#-installation)
- [🎬 Getting started](#-getting-started)
- [🤖 Compatibility with Meilisearch](#-compatibility-with-meilisearch)
- [💡 Learn more](#-learn-more)
- [⚙️ Contributing](#️-contributing)
- [📜 API resources](#-api-resources)

## 📖 Documentation

This readme contains all the documentation you need to start using this Meilisearch SDK.

For general information on how to use Meilisearch—such as our API reference, tutorials, guides, and in-depth articles—refer to our [main documentation website](https://meilisearch.com/docs).

## 🔧 Installation

The package can be installed by adding `meilisearch_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:finch, "~> 0.14.0"},
    {:meilisearch_ex, "~> 1.1.1"}
  ]
end
```

`meilisearch-ex` officially supports `elixir` versions >= 1.14

### Run Meilisearch <!-- omit in toc -->

To use one of our SDKs, you must first have a running Meilisearch instance. Consult our documentation for [instructions on how to download and launch Meilisearch](https://www.meilisearch.com/docs/learn/getting_started/installation#installation).

## Usage

There is multiple ways to define and start the Meilisearch client:

```elixir
# Start finch with your app
Finch.start_link(name: :search_finch)

# Create a Meilisearch client whenever and wherever you need it.
[endpoint: "http://127.0.0.1:7700", key: "masterKey", finch: :search_finch]
|> Meilisearch.Client.new()
|> Meilisearch.Health.get()

# %Meilisearch.Health{status: "available"}
```

But you can also start a client alongside your application to access it whenever you need it.

```elixir
Finch.start_link(name: :search_finch)

Meilisearch.start_link(:main, [
  endpoint: "http://127.0.0.1:7700",
  key: "replace_me",
  finch: :search_finch
])

:main
|> Meilisearch.client()
|> Meilisearch.Health.get()

# %Meilisearch.Health{status: "available"}
```

Within a Phoenix app you would do like this:

```elixir
defmodule MyApp.Application do
  # ...

  @impl true
  def start(_type, _args) do
    children = [
      # ...
      {Finch, name: :search_finch},
      {Meilisearch, name: :search_admin, endpoint: "http://127.0.0.1:7700", key: "key_admin", finch: :search_finch},
      {Meilisearch, name: :search_public, endpoint: "http://127.0.0.1:7700", key: "key_public", finch: :search_finch}
    ]

    # ...
  end

  # ...
end

defmodule MyApp.MyContext do
  def create_search_index() do
    :search_admin
    |> Meilisearch.client()
    |> Meilisearch.Index.create(%{uid: "items", primaryKey: "id"})
  end

  def add_documents_to_search_index(documents) do
    :search_admin
    |> Meilisearch.client()
    |> Meilisearch.Document.create_or_replace("items", documents)
  end

  def search_document(query) do
    :search_public
    |> Meilisearch.client()
    |> Meilisearch.Search.search("items", %{q: query})
  end
end
```

### Using another HTTP adapter

Given that the HTTP client is backed by Tesla behind the scene, you can freely use another adapter if it is more suitable for you.

```elixir
def deps do
  [
    {:hackney, "~> 1.18"},
    {:meilisearch_ex, "~> 1.1.1"}
  ]
end
```
```elixir

# Create a Meilisearch client whenever and wherever you need it.
[endpoint: "http://127.0.0.1:7700", key: "masterKey", adapter: Tesla.Adapter.Hackney]
|> Meilisearch.Client.new()
|> Meilisearch.Health.get()

# %Meilisearch.Health{status: "available"}
```



## 🎬 Getting started

### Add documents <!-- omit in toc -->

```elixir
# Create the Meilisearch instance
Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "masterKey")
# If the index 'movies' does not exist, Meilisearch creates it when you first add the documents.
|> Meilisearch.Document.create_or_replace(
  "movies",
  [
    %{id: 1, title: "Carol", genres: ["Romance", "Drama"]},
    %{id: 2, title: "Wonder Woman", genres: ["Action", "Adventure"]},
    %{id: 3, title: "Life of Pi", genres: ["Adventure", "Drama"]},
    %{id: 4, title: "Mad Max: Fury Road", genres: ["Adventure", "Science Fiction"]},
    %{id: 5, title: "Moana", genres: ["Fantasy", "Action"]},
    %{id: 6, title: "Philadelphia", genres: ["Drama"]}
  ]
)
# => {
#  :ok,
#  %{taskUid: 0, indexUid: "movies", status: :enqueued, type: :documentAdditionOrUpdate, enqueuedAt: ~U[..] }
# }
```

Tasks such as document addition always return a unique identifier. You can use this identifier `taskUid` to check the status (`enqueued`, `processing`, `succeeded` or `failed`) of a [task](https://www.meilisearch.com/docs/reference/api/tasks).

### Basic search <!-- omit in toc -->

```elixir
# Meilisearch is typo-tolerant:
Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "masterKey")
|> Meilisearch.Search.search("movies", q: "philoudelphia")
```

Output:

```elixir
{:ok, %{
  offset: 0,
  limit: 20,
  estimatedTotalHits: 1,
  processingTimeMs: 1,
  query: "philoudelphia",
  hits: [%{
    "id" => "6",
    "title" => "Philadelphia",
    "genres" => ["Drama"]
  }]
}}
```

## 🤖 Compatibility with Meilisearch

This package guarantees compatibility with [version v1.x of Meilisearch](https://github.com/meilisearch/meilisearch/releases/latest), but some features may not be present. Please check the [issues](https://github.com/nutshell-lab/meilisearch-ex/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22+label%3Aenhancement) for more info.

## 💡 Learn more

The following sections in our main documentation website may interest you:

- **Manipulate documents**: see the [API references](https://www.meilisearch.com/docs/reference/api/documents) or read more about [documents](https://www.meilisearch.com/docs/learn/core_concepts/documents.html).
- **Search**: see the [API references](https://www.meilisearch.com/docs/reference/api/search) or follow our guide on [search parameters](https://www.meilisearch.com/docs/reference/api/search#search-parameters).
- **Manage the indexes**: see the [API references](https://www.meilisearch.com/docs/reference/api/indexes) or read more about [indexes](https://www.meilisearch.com/docs/learn/core_concepts/indexes.html).
- **Configure the index settings**: see the [API references](https://www.meilisearch.com/docs/reference/api/settings) or follow our guide on [settings parameters](https://www.meilisearch.com/docs/reference/api/settings#settings_parameters).

This repository also contains [more examples](./examples).

## ⚙️ Contributing

We welcome all contributions, big and small! If you want to know more about this SDK's development workflow or want to contribute to the repo, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions.
