defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  @image "getmeili/meilisearch:v1.0.0"
  @master_key "master_key_test"

  defp master_opts(meili),
    do: [endpoint: MeilisearchTest.MeiliContainer.connection_url(meili), key: @master_key]

  test "Meilisearch manually instanciating a client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))

    with {:ok, health} <-
           master_opts(meili)
           |> Meilisearch.Client.new()
           |> Meilisearch.Health.get() do
      assert %Meilisearch.Health{
               status: "available"
             } = health
    else
      _ -> flunk("Mailisearch is unavailable")
    end
  end

  test "Meilisearch using a GenServer to retreive named client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    with {:ok, health} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Health.get() do
      assert %Meilisearch.Health{
               status: "available"
             } = health
    else
      _ -> flunk("Mailisearch is unavailable")
    end
  end

  test "Full tour arround the api" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    # List of indexes, should be empty
    with {:ok, indexes} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.list(limit: 20, offset: 0) do
      assert %Meilisearch.Pagination{
               results: [],
               offset: 0,
               limit: 20,
               total: 0
             } = indexes
    else
      _ -> flunk("List index failed")
    end

    # Creating an index, a task should be enqueued
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.create(%{uid: "movies", primaryKey: "id"}) do
      assert %Meilisearch.Task{
               taskUid: 0,
               indexUid: "movies",
               status: :enqueued,
               type: :indexCreation
             } = task
    else
      _ -> flunk("Create index failed")
    end

    # Wait for the task to finish
    :timer.sleep(1000)

    # Index should be created
    with {:ok, index} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.get("movies") do
      assert %Meilisearch.Index{
               uid: "movies",
               primaryKey: "id"
             } = index
    else
      _ -> flunk("Get index failed")
    end

    # Let's update the index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.update("movies", %{primaryKey: "uuid"}) do
      assert %Meilisearch.Task{
               taskUid: 1,
               indexUid: "movies",
               status: :enqueued,
               type: :indexUpdate
             } = task
    else
      _ -> flunk("Update index failed")
    end

    # Wait for the task to finish
    :timer.sleep(1000)

    # Index should be updated
    with {:ok, index} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.get("movies") do
      assert %Meilisearch.Index{
               uid: "movies",
               primaryKey: "uuid"
             } = index
    else
      _ -> flunk("Get index failed")
    end

    # Let's delete our index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.delete("movies") do
      assert %Meilisearch.Task{
               taskUid: 2,
               indexUid: "movies",
               status: :enqueued,
               type: :indexDeletion
             } = task
    else
      _ -> flunk("Delete index failed")
    end

    # Wait for the tasks to finish
    :timer.sleep(1000)

    # Our index should be gone
    with {:error, error, status} <-
           :main |> Meilisearch.client() |> Meilisearch.Index.get("movies") do
      assert 404 = status
      assert %Meilisearch.Error{
               type: :invalid_request,
               code: :index_not_found,
               message: "Index `movies` not found.",
               link: "https://docs.meilisearch.com/errors#index_not_found"
             } = error
    else
      _ -> flunk("Update index failed")
    end
  end
end
