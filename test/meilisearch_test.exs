defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  defmodule Movie do
    defstruct [:uuid, :title, :director, :genres]
  end

  @meiliversion "1.0.2"
  @image "getmeili/meilisearch:v#{@meiliversion}"
  @master_key "master_key_test"

  defp master_opts(meili),
    do: [
      endpoint: MeilisearchTest.MeiliContainer.connection_url(meili),
      key: @master_key,
      debug: false
    ]

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

  test "Meilisearch unhealthy client" do
    refute [
             endpoint: "https://non_existsnt_domain",
             key: "dummy",
             timeout: 1_000
           ]
           |> Meilisearch.Client.new()
           |> Meilisearch.Health.healthy?()
  end

  test "Meilisearch manually instanciating a client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))

    assert true =
             master_opts(meili)
             |> Meilisearch.Client.new()
             |> Meilisearch.Health.healthy?()
  end

  test "Meilisearch using a GenServer to retreive named client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    assert true =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Health.healthy?()
  end

  test "Full tour arround the api" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

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
    assert {:ok,
            %Meilisearch.Version{
              pkgVersion: @meiliversion
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
                  uid: "movies",
                  primaryKey: "id"
                }
              ],
              offset: 0,
              limit: 20,
              total: 1
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
               %Movie{uuid: 2, title: "Superbat", director: "Rico", genres: ["commedy", "polar"]}
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
                  "genres" => ["commedy", "polar"]
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
              "genres" => ["commedy", "polar"]
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
               %Movie{uuid: 2, title: "Superbat", director: "Rico", genres: ["commedy", "polar"]}
             ])

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
             |> Meilisearch.Settings.TypeTolerence.update("movies", %{
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
             |> Meilisearch.Settings.TypeTolerence.get("movies")

    assert {:ok,
            %Meilisearch.SummarizedTask{
              taskUid: task,
              indexUid: "movies",
              status: :enqueued,
              type: :settingsUpdate
            }} =
             :main
             |> Meilisearch.client()
             |> Meilisearch.Settings.TypeTolerence.reset("movies")

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
             |> Meilisearch.Settings.TypeTolerence.get("movies")

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
