defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  @image "getmeili/meilisearch:v1.0.0"
  @master_key "master_key_test"

  defp master_opts(meili),
    do: [endpoint: MeilisearchTest.MeiliContainer.connection_url(meili), key: @master_key]

  test "Meilisearch manually instanciating a client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))

    health =
      master_opts(meili)
      |> Meilisearch.Client.new()
      |> Meilisearch.Health.get()

    assert health == {:ok, %{status: "available"}}
  end

  test "Meilisearch using a GenServer to retreive named client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    health =
      :main
      |> Meilisearch.client()
      |> Meilisearch.Health.get()

    assert health == {:ok, %{status: "available"}}
  end

  test "Full tour arround the api" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    # List of indexes, should be empty
    with {:ok, list} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.list(limit: 20, offset: 0) do
      assert list == %{results: [], offset: 0, limit: 20, total: 0}
    else
      _ -> flunk("List index failed")
    end

    # Creating an index, a task should be enqueued
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.create(%{uid: "movies", primaryKey: "id"}) do
      assert task.taskUid == 0
      assert task.indexUid == "movies"
      assert task.status == :enqueued
      assert task.type == :indexCreation
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
      assert index.uid == "movies"
      assert index.primaryKey == "id"
    else
      _ -> flunk("Get index failed")
    end

    # Let's update the index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.update("movies", %{primaryKey: "uuid"}) do
      assert task.taskUid == 1
      assert task.indexUid == "movies"
      assert task.status == :enqueued
      assert task.type == :indexUpdate
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
      assert index.uid == "movies"
      assert index.primaryKey == "uuid"
    else
      _ -> flunk("Get index failed")
    end

    # Let's create an updated version of our index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.create(%{uid: "movies_new", primaryKey: "id"}) do
      assert task.taskUid == 2
      assert task.indexUid == "movies_new"
      assert task.status == :enqueued
      assert task.type == :indexCreation
    else
      _ -> flunk("Create index failed")
    end

    # Let's delete our index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.delete("movies") do
      assert task.taskUid == 3
      assert task.indexUid == "movies"
      assert task.status == :enqueued
      assert task.type == :indexDeletion
    else
      _ -> flunk("Delete index failed")
    end

    # Wait for the tasks to finish
    :timer.sleep(1000)

    # Our index should be gone
    with {:error, response} <-
           :main |> Meilisearch.client() |> Meilisearch.Index.get("movies") do
      assert response.status == 404
      assert response.body.code == "index_not_found"
      assert response.body.message == "Index `movies` not found."
    else
      _ -> flunk("Update index failed")
    end
  end
end
