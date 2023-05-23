defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  defmodule Movie do
    defstruct [:uuid, :title, :director, :genres]
  end

  defmodule Book do
    defstruct [:uuid, :title, :author, :genres]
  end

  setup do
    # Used in CI to test multiple versions of Meilisearch
    version = System.get_env("MEILI", "1.1.1")
    image = "getmeili/meilisearch:v#{version}"
    key = "master_key_test"

    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(image, key: key))

    Finch.start_link(name: :meili_finch)

    [
      version: version,
      meili: [
        endpoint: MeilisearchTest.MeiliContainer.connection_url(meili),
        key: key,
        debug: false,
        finch: :meili_finch
      ]
    ]
  end

  def wait_for_task(client, taskUid, backoff \\ 500) do
    case Meilisearch.Task.get(client, taskUid) do
      {:error, error} ->
        {:error, error}

      {:ok, %Meilisearch.Task{status: :succeeded}} ->
        :succeeded

      {:ok, %Meilisearch.Task{status: :failed}} ->
        :failed

      {:ok, %Meilisearch.Task{status: :canceled}} ->
        :canceled

      {:ok, _task} ->
        Process.sleep(backoff)
        wait_for_task(client, taskUid, backoff * 2)
    end
  end

  test "Meilisearch unhealthy client", _context do
    refute [
             endpoint: "https://non_existsnt_domain",
             key: "dummy",
             timeout: 1_000,
             finch: :meili_finch
           ]
           |> Meilisearch.Client.new()
           |> Meilisearch.Health.healthy?()
  end

  test "Meilisearch manually instantiating a client", context do
    assert true =
             context[:meili]
             |> Meilisearch.Client.new()
             |> Meilisearch.Health.healthy?()
  end

  test "Meilisearch using a GenServer to retrieve named client", context do
    Meilisearch.start_link(:main, context[:meili])

    assert true =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Health.healthy?()
  end

  test "Meilisearch manipulate keys", context do
    Meilisearch.start_link(:main, context[:meili])

    assert {:ok,
            %{
              offset: 0,
              limit: 20,
              total: 2,
              results: [
                %{
                  name: "Default Search API Key",
                  description: "Use it to search from the frontend",
                  key: _,
                  uid: _,
                  actions: ["search"],
                  indexes: ["*"],
                  expiresAt: nil,
                  createdAt: _,
                  updatedAt: _
                },
                %{
                  name: "Default Admin API Key",
                  description:
                    "Use it for anything that is not a search operation. Caution! Do not expose it on a public frontend",
                  key: _,
                  uid: admin_key,
                  actions: ["*"],
                  indexes: ["*"],
                  expiresAt: nil,
                  createdAt: _,
                  updatedAt: _
                }
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Key.list()

    assert {:ok,
            %{
              name: "Default Admin API Key",
              description:
                "Use it for anything that is not a search operation. Caution! Do not expose it on a public frontend",
              key: _,
              uid: ^admin_key,
              actions: ["*"],
              indexes: ["*"],
              expiresAt: nil,
              createdAt: _,
              updatedAt: _
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Key.get(admin_key)

    assert {:ok,
            %{
              name: "SUPERKEY",
              description: nil,
              key: _,
              uid: superkey,
              actions: ["*"],
              indexes: ["*"],
              expiresAt: nil,
              createdAt: _,
              updatedAt: _
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Key.create(%{
               name: "SUPERKEY",
               actions: ["*"],
               indexes: ["*"],
               expiresAt: nil
             })

    assert {:ok,
            %{
              name: "SUPERKEY",
              description: "Super key ?",
              key: _,
              uid: ^superkey,
              actions: ["*"],
              indexes: ["*"],
              expiresAt: nil,
              createdAt: _,
              updatedAt: _
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Key.update(superkey, %{
               description: "Super key ?"
             })

    assert {:ok, nil} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Key.delete(superkey)
  end

  test "Full tour around the api", context do
    Meilisearch.start_link(:main, context[:meili])

    # Instance should be healthy
    assert true =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Health.healthy?()

    assert {:ok, %{status: "available"}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Health.get()

    # Instance should be of @meiliversion
    version = context[:version]

    assert {:ok,
            %Meilisearch.Version{
              pkgVersion: ^version
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Version.get()

    # List of indexes, should be empty
    assert {:ok,
            %Meilisearch.Pagination{
              results: [],
              offset: 0,
              limit: 20,
              total: 0
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.list(limit: 20, offset: 0)

    # Creating an index, a task should be enqueued
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :indexCreation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.create(%{uid: "movies", primaryKey: "id"})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "books",
              status: :enqueued,
              type: :indexCreation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.create(%{uid: "books", primaryKey: "uuid"})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Index should be created
    assert {:ok,
            %Meilisearch.Index{
              uid: "movies",
              primaryKey: "id"
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.get("movies")

    # List of indexes, should NOT be empty
    assert {:ok,
            %Meilisearch.Pagination{
              results: [
                %{
                  uid: "books",
                  primaryKey: "uuid"
                },
                %{
                  uid: "movies",
                  primaryKey: "id"
                }
              ],
              offset: 0,
              limit: 20,
              total: 2
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.list(limit: 20, offset: 0)

    # Let's update the index
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :indexUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.update("movies", %{primaryKey: "uuid"})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Index should be updated
    assert {:ok,
            %Meilisearch.Index{
              uid: "movies",
              primaryKey: "uuid"
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.get("movies")

    require Protocol
    Protocol.derive(Jason.Encoder, Movie)

    # Let's insert some documents
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_replace("movies", [
               %Movie{uuid: 1, title: "Flatman", director: "Roberto", genres: ["sf", "drama"]},
               %Movie{uuid: 2, title: "Superbat", director: "Rico", genres: ["comedy", "polar"]}
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_replace("movies", %Movie{
               uuid: 2,
               title: "Superbat",
               director: "Rico",
               genres: ["comedy", "polar"]
             })

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    Protocol.derive(Jason.Encoder, Book)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "books",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_replace("books", [
               %Book{uuid: 1, title: "FlatmanB", author: "RobertoB", genres: ["sf", "drama"]},
               %Book{uuid: 2, title: "SuperbatB", author: "RicoB", genres: ["comedy", "polar"]}
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Let's get stats about our index
    assert {:ok,
            %{
              numberOfDocuments: 2,
              isIndexing: false,
              fieldDistribution: %{
                "director" => 2,
                "genres" => 2,
                "title" => 2,
                "uuid" => 2
              }
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Stats.get("movies")

    assert {:ok,
            %{
              indexes: %{
                "movies" => %{
                  numberOfDocuments: 2,
                  isIndexing: false,
                  fieldDistribution: %{
                    "director" => 2,
                    "genres" => 2,
                    "title" => 2,
                    "uuid" => 2
                  }
                }
              }
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Stats.all()

    # Let's search
    assert {:ok,
            %Meilisearch.Search{
              query: nil,
              hits: [
                %{
                  "uuid" => 1,
                  "title" => "Flatman",
                  "director" => "Roberto",
                  "genres" => ["sf", "drama"]
                },
                %{
                  "uuid" => 2,
                  "title" => "Superbat",
                  "director" => "Rico",
                  "genres" => ["comedy", "polar"]
                }
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Search.search("movies")

    assert {:ok,
            %Meilisearch.Search{
              query: "flat",
              hits: [
                %{
                  "uuid" => 1,
                  "title" => "Flatman",
                  "director" => "Roberto",
                  "genres" => ["sf", "drama"]
                }
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Search.search("movies", %{q: "flat"})

    assert {:ok,
            %Meilisearch.Search{
              query: "flat",
              hits: [
                %{
                  "uuid" => 1,
                  "title" => "Flatman",
                  "director" => "Roberto",
                  "genres" => ["sf", "drama"]
                }
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Search.search("movies", q: "flat", limit: 1)

    # Let's multi-search
    if version > "1.1.0" do
      assert {:ok,
              [
                %Meilisearch.MultiSearch{
                  indexUid: "books",
                  query: nil,
                  hits: [
                    %{
                      "uuid" => 1,
                      "title" => "FlatmanB",
                      "author" => "RobertoB",
                      "genres" => ["sf", "drama"]
                    },
                    %{
                      "uuid" => 2,
                      "title" => "SuperbatB",
                      "author" => "RicoB",
                      "genres" => ["comedy", "polar"]
                    }
                  ]
                },
                %Meilisearch.MultiSearch{
                  indexUid: "movies",
                  query: nil,
                  hits: [
                    %{
                      "uuid" => 1,
                      "title" => "Flatman",
                      "director" => "Roberto",
                      "genres" => ["sf", "drama"]
                    },
                    %{
                      "uuid" => 2,
                      "title" => "Superbat",
                      "director" => "Rico",
                      "genres" => ["comedy", "polar"]
                    }
                  ]
                }
              ]} =
               :main
               |> Meilisearch.client()
               |> Meilisearch.MultiSearch.multi_search(%{"books" => [], "movies" => []})

      assert {:ok,
              [
                %Meilisearch.MultiSearch{
                  indexUid: "books",
                  query: "flat",
                  hits: [
                    %{
                      "uuid" => 1,
                      "title" => "FlatmanB",
                      "author" => "RobertoB",
                      "genres" => ["sf", "drama"]
                    }
                  ]
                },
                %Meilisearch.MultiSearch{
                  indexUid: "movies",
                  query: "flat",
                  hits: [
                    %{
                      "uuid" => 1,
                      "title" => "Flatman",
                      "director" => "Roberto",
                      "genres" => ["sf", "drama"]
                    }
                  ]
                }
              ]} =
               :main
               |> Meilisearch.client()
               |> Meilisearch.MultiSearch.multi_search(%{
                 "books" => [q: "flat"],
                 "movies" => [q: "flat"]
               })
    end

    # Let's list all our documents
    assert {:ok,
            %{
              offset: 0,
              limit: 2,
              total: 2,
              results: [
                %{
                  "uuid" => 1,
                  "title" => "Flatman",
                  "director" => "Roberto",
                  "genres" => ["sf", "drama"]
                },
                %{
                  "uuid" => 2,
                  "title" => "Superbat",
                  "director" => "Rico",
                  "genres" => ["comedy", "polar"]
                }
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.list("movies", limit: 2)

    assert {:ok,
            %{
              "uuid" => 2,
              "title" => "Superbat",
              "director" => "Rico",
              "genres" => ["comedy", "polar"]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.get("movies", 2)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentDeletion
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.delete_one("movies", 2)

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentDeletion
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.delete_batch("movies", [1])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_update("movies", [
               %Movie{uuid: 1, title: "Flatman", director: "Roberto", genres: ["sf", "drama"]},
               %Movie{uuid: 2, title: "Superbat", director: "Rico", genres: ["comedy", "polar"]}
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_update("movies", %Movie{
               uuid: 2,
               title: "Superbat",
               director: "Rico",
               genres: ["comedy", "polar"]
             })

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :documentDeletion
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.delete_all("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Check default settings
    assert {:ok,
            %Meilisearch.Settings{
              displayedAttributes: ["*"],
              searchableAttributes: ["*"],
              filterableAttributes: [],
              sortableAttributes: [],
              rankingRules: ["words", "typo", "proximity", "attribute", "sort", "exactness"],
              stopWords: [],
              synonyms: %{},
              distinctAttribute: nil,
              typoTolerance: %{
                enabled: true,
                minWordSizeForTypos: %{
                  oneTypo: 5,
                  twoTypos: 9
                },
                disableOnWords: [],
                disableOnAttributes: []
              },
              faceting: %{
                maxValuesPerFacet: 100
              },
              pagination: %{
                maxTotalHits: 1000
              }
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.get("movies")

    # Update some settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DistinctAttributes.update("movies", "uuid")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, "uuid"} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DistinctAttributes.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DistinctAttributes.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, nil} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DistinctAttributes.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DisplayedAttributes.update("movies", [
               "uuid",
               "title",
               "director"
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["uuid", "title", "director"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DisplayedAttributes.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DisplayedAttributes.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["*"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.DisplayedAttributes.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SearchableAttributes.update("movies", [
               "title",
               "director"
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["title", "director"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SearchableAttributes.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SearchableAttributes.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["*"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SearchableAttributes.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.FilterableAttributes.update("movies", [
               "director",
               "genres"
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["director", "genres"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.FilterableAttributes.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.FilterableAttributes.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, []} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.FilterableAttributes.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SortableAttributes.update("movies", ["title"])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["title"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SortableAttributes.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SortableAttributes.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, []} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.SortableAttributes.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Faceting.update("movies", %{maxValuesPerFacet: 20})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, %{maxValuesPerFacet: 20}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Faceting.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Faceting.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, %{maxValuesPerFacet: 100}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Faceting.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Pagination.update("movies", %{maxTotalHits: 50})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, %{maxTotalHits: 50}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Pagination.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Pagination.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, %{maxTotalHits: 1_000}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Pagination.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.TypeTolerance.update("movies", %{
               enabled: true,
               minWordSizeForTypos: %{
                 oneTypo: 6,
                 twoTypos: 12
               },
               disableOnWords: ["skrek"],
               disableOnAttributes: ["uuid"]
             })

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %{
              enabled: true,
              minWordSizeForTypos: %{
                oneTypo: 6,
                twoTypos: 12
              },
              disableOnWords: ["skrek"],
              disableOnAttributes: ["uuid"]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.TypeTolerance.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.TypeTolerance.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %{
              enabled: true,
              minWordSizeForTypos: %{
                oneTypo: 5,
                twoTypos: 9
              },
              disableOnWords: [],
              disableOnAttributes: []
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.TypeTolerance.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Synonyms.update("movies", %{
               "wolverine" => ["logan", "xmen"],
               "logan" => ["wolverine", "xmen"],
               "wow" => ["world of warcraft"]
             })

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %{
              "wolverine" => ["logan", "xmen"],
              "logan" => ["wolverine", "xmen"],
              "wow" => ["world of warcraft"]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Synonyms.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Synonyms.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, %{}} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.Synonyms.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.StopWords.update("movies", ["of", "the", "to"])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["of", "the", "to"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.StopWords.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.StopWords.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, []} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.StopWords.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.RankingRules.update("movies", [
               "words",
               "typo",
               "proximity",
               "attribute",
               "sort",
               "exactness",
               "title:asc"
             ])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["words", "typo", "proximity", "attribute", "sort", "exactness", "title:asc"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.RankingRules.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.RankingRules.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok, ["words", "typo", "proximity", "attribute", "sort", "exactness"]} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.RankingRules.get("movies")

    # -- next settings
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.update("movies", %{
               rankingRules: [
                 "words",
                 "typo",
                 "proximity",
                 "attribute",
                 "sort",
                 "exactness",
                 "title:asc"
               ]
             })

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %{
              rankingRules: [
                "words",
                "typo",
                "proximity",
                "attribute",
                "sort",
                "exactness",
                "title:asc"
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.reset("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %{
              rankingRules: [
                "words",
                "typo",
                "proximity",
                "attribute",
                "sort",
                "exactness"
              ]
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.get("movies")

    # Insert a lot of documents and cancel the task
    big_list_of_movies =
      5..5_000
      |> Enum.to_list()
      |> Enum.map(fn i ->
        %Movie{uuid: i, title: "Flatman", director: "Roberto", genres: ["sf", "drama"]}
      end)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task_to_cancel,
              indexUid: "movies",
              status: :enqueued,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Document.create_or_replace("movies", big_list_of_movies)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: cancelation_task,
              indexUid: nil,
              status: :enqueued,
              type: :taskCancelation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.cancel(uids: "#{task_to_cancel}")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), cancelation_task)

    assert {:ok,
            %Meilisearch.Task{
              uid: _,
              indexUid: "movies",
              status: :canceled,
              type: :documentAdditionOrUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.get(task_to_cancel)

    assert {:ok,
            %Meilisearch.Task{
              uid: _,
              indexUid: nil,
              status: :succeeded,
              type: :taskCancelation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.get(cancelation_task)

    # Let's swap our index with another
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies_new",
              status: :enqueued,
              type: :indexCreation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.create(%{uid: "movies_new", primaryKey: "id"})

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: nil,
              status: :enqueued,
              type: :indexSwap
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.swap([%{indexes: ["movies", "movies_new"]}])

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Let's delete our index
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :indexDeletion
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Index.delete("movies")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    # Our index should be gone
    assert {:error,
            %Meilisearch.Error{
              type: :invalid_request,
              code: :index_not_found,
              message: "Index `movies` not found.",
              link: "https://docs.meilisearch.com/errors#index_not_found"
            }, 404} = :main |> Meilisearch.client() |> Meilisearch.Index.get("movies")

    # Cleanup all succeeded tasks
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: nil,
              status: :enqueued,
              type: :taskDeletion
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.delete(statuses: "succeeded,canceled")

    assert :succeeded = wait_for_task(Meilisearch.client(:main), task)

    assert {:ok,
            %Meilisearch.PaginatedTasks{
              results: [
                %Meilisearch.Task{
                  uid: _,
                  indexUid: nil,
                  status: :succeeded,
                  type: :taskDeletion,
                  canceledBy: nil,
                  details: %{
                    "deletedTasks" => _,
                    "matchedTasks" => _,
                    "originalFilter" => "?statuses=succeeded%2Ccanceled"
                  },
                  error: nil,
                  duration: _,
                  enqueuedAt: _,
                  startedAt: _,
                  finishedAt: _
                }
              ],
              limit: 10,
              from: _,
              next: nil
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.list(limit: 10)

    # Dump our sweet instance
    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: _,
              indexUid: nil,
              status: :enqueued,
              type: :dumpCreation
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Dump.create()
  end
end
