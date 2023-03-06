defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  defmodule Movie do
    defstruct [:uuid, :title, :director, :genres]
  end

  @image "getmeili/meilisearch:v1.0.2"
  @master_key "master_key_test"

  defp master_opts(meili),
    do: [endpoint: MeilisearchTest.MeiliContainer.connection_url(meili), key: @master_key]

  def wait_for_task(client, taskUid, backoff \\ 1_000) do
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

  test "Meilisearch manually instanciating a client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))

    with healthy <-
           master_opts(meili)
           |> Meilisearch.Client.new()
           |> Meilisearch.Health.healthy?() do
      assert true = healthy
    else
      _ -> flunk("Mailisearch is unavailable")
    end
  end

  test "Meilisearch using a GenServer to retreive named client" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    with healthy <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Health.healthy?() do
      assert true = healthy
    else
      _ -> flunk("Mailisearch is unavailable")
    end
  end

  test "Full tour arround the api" do
    {:ok, meili} = run_container(MeilisearchTest.MeiliContainer.new(@image, key: @master_key))
    Meilisearch.start_link(:main, master_opts(meili))

    # Instance should be healthy
    with healthy <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Health.healthy?() do
      assert true = healthy
    else
      _ -> flunk("Mailisearch is unavailable")
    end

    # Instance should be of 1.0.2
    with {:ok, version} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Version.get() do
      assert %Meilisearch.Version{
               pkgVersion: "1.0.2"
             } = version
    else
      _ -> flunk("Mailisearch is unavailable")
    end

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
      assert %Meilisearch.SummarizedTask{
               taskUid: 0,
               indexUid: "movies",
               status: :enqueued,
               type: :indexCreation
             } = task

      assert :succeeded = wait_for_task(Meilisearch.client(:main), task.taskUid)
    else
      _ -> flunk("Create index failed")
    end

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
      assert %Meilisearch.SummarizedTask{
               taskUid: _,
               indexUid: "movies",
               status: :enqueued,
               type: :indexUpdate
             } = task

      assert :succeeded = wait_for_task(Meilisearch.client(:main), task.taskUid)
    else
      _ -> flunk("Update index failed")
    end

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

    require Protocol
    Protocol.derive(Jason.Encoder, Movie)

    # Let's insert some documents
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Document.create_or_replace("movies", [
             %Movie{uuid: 1, title: "Flatman", director: "Roberto", genres: ["sf", "drama"]},
             %Movie{uuid: 2, title: "Superbat", director: "Rico", genres: ["commedy", "polar"]}
           ]) do
      assert %Meilisearch.SummarizedTask{
               taskUid: _,
               indexUid: "movies",
               status: :enqueued,
               type: :documentAdditionOrUpdate
             } = task

      assert :succeeded = wait_for_task(Meilisearch.client(:main), task.taskUid)
    else
      _ -> flunk("Document insertion failed")
    end

    # Let's search
    with {:ok, search} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Search.search("movies", %{q: "flat"}) do
      assert %Meilisearch.Search{
               query: "flat",
               hits: [
                 %{
                   "uuid" => 1,
                   "title" => "Flatman",
                   "director" => "Roberto",
                   "genres" => ["sf", "drama"]
                 }
               ]
             } = search
    else
      _ -> flunk("Search failed")
    end

    # Creating an index, and cancel the task
    big_list_of_movies = 5..5_000
    |> Enum.to_list()
    |> Enum.map(fn i -> %Movie{uuid: i, title: "Flatman", director: "Roberto", genres: ["sf", "drama"]} end)

    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Document.create_or_replace("movies", big_list_of_movies),
         {:ok, cancelation_task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Task.cancel(uids: "#{task.taskUid}") do
      assert %Meilisearch.SummarizedTask{
               taskUid: _,
               indexUid: "movies",
               status: :enqueued,
               type: :documentAdditionOrUpdate
             } = task

      assert %Meilisearch.SummarizedTask{
               taskUid: _,
               indexUid: nil,
               status: :enqueued,
               type: :taskCancelation
             } = cancelation_task

      assert :succeeded = wait_for_task(Meilisearch.client(:main), cancelation_task.taskUid)

      with {:ok, canceled_task} <-
             :main
             |> Meilisearch.client()
             |> Meilisearch.Task.get(task.taskUid) do
        assert %Meilisearch.Task{
                 uid: _,
                 indexUid: "movies",
                 status: :canceled,
                 type: :documentAdditionOrUpdate
               } = canceled_task
      else
        _ -> flunk("Task cancelation failed")
      end
    else
      _ -> flunk("Task cancelation failed")
    end

    # Let's delete our index
    with {:ok, task} <-
           :main
           |> Meilisearch.client()
           |> Meilisearch.Index.delete("movies") do
      assert %Meilisearch.SummarizedTask{
               taskUid: _,
               indexUid: "movies",
               status: :enqueued,
               type: :indexDeletion
             } = task

      assert :succeeded = wait_for_task(Meilisearch.client(:main), task.taskUid)
    else
      _ -> flunk("Delete index failed")
    end

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
