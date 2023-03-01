defmodule Meilisearch.Document do
  @moduledoc """
  Manipulate Meilisearch documents.
  Documents are not parsed into anything and are returned as plain maps with string keys.
  [Document API](https://docs.meilisearch.com/references/documents.html)
  """

  @type t() :: map()
  @type document_id() :: String.t() | integer()

  @doc """
  List Documents of an Index of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#get-documents)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Documents.list(client, "movies", limit: 20, offset: 0)
      {:ok, %{offset: 0, limit: 20, total: 1, results: [%{
        "id" => 2001,
        "title" => "2001: A Space Odyssey"
      }]}}

  """
  @spec list(Tesla.Client.t(), String.t(),
          offset: integer(),
          limit: integer(),
          fields: list(String.t())
        ) ::
          {:ok, Meilisearch.Pagination.t(__MODULE__.t())}
          | {:error, Meilisearch.Client.error()}
  def list(client, index_uid, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes/:index_uid/documents",
             query: opts,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Pagination.cast(data)}
    end
  end

  @doc """
  Get an Document of an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#get-one-document)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.get(client, "movies", 25684)
      {:ok, %{
        "id" => 25684,
        "title" => "American Ninja 5"
      }}

  """
  @spec get(Tesla.Client.t(), String.t(), document_id()) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def get(client, index_uid, document_id) do
    client
    |> Tesla.get("/indexes/:index_uid/documents/:document_id",
      opts: [path_params: [index_uid: index_uid, document_id: document_id]]
    )
    |> Meilisearch.Client.handle_response()
  end

  @doc """
  Create or update a Documents into an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#add-or-replace-documents)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.create_or_replace(client, "movies", [%{id: 25684, title: "American Ninja 5"}])
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :documentAdditionOrUpdate,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec create_or_replace(Tesla.Client.t(), String.t(), list(__MODULE__.t()) | __MODULE__.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def create_or_replace(client, index_uid, params) when not is_list(params),
    do: create_or_replace(client, index_uid, [params])

  def create_or_replace(client, index_uid, params) do
    with {:ok, data} <-
           client
           |> Tesla.post("/indexes/:index_uid/documents", params,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Task.cast(data)}
    end
  end

  @doc """
  Create or update a Documents into an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#add-or-update-documents)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.create_or_update(client, "movies", [%{id: 25684, title: "American Ninja 5"}])
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :documentAdditionOrUpdate,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec create_or_update(Tesla.Client.t(), String.t(), list(__MODULE__.t()) | __MODULE__.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def create_or_update(client, index_uid, params) when not is_list(params),
    do: create_or_update(client, index_uid, [params])

  def create_or_update(client, index_uid, params) do
    with {:ok, data} <-
           client
           |> Tesla.put("/indexes/:index_uid/documents", params,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Task.cast(data)}
    end
  end

  @doc """
  Delete all Documents of an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#delete-all-documents)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.delete_all(client, "movies")
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :documentDeletion,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec delete_all(Tesla.Client.t(), String.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def delete_all(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.delete("/indexes/:index_uid/documents",
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Task.cast(data)}
    end
  end

  @doc """
  Delete one Documents of an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#delete-one-document)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.delete_one(client, "movies", 25684)
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :documentDeletion,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec delete_one(Tesla.Client.t(), String.t(), document_id()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def delete_one(client, index_uid, document_id) do
    with {:ok, data} <-
           client
           |> Tesla.delete("/indexes/:index_uid/documents/:document_id",
             opts: [path_params: [index_uid: index_uid, document_id: document_id]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Task.cast(data)}
    end
  end

  @doc """
  Delete a batch of Documents of an Index in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/documents.html#delete-documents-by-batch)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Document.delete_batch(client, "movies", [25684, 12435])
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :documentDeletion,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec delete_batch(Tesla.Client.t(), String.t(), list(document_id())) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def delete_batch(client, index_uid, document_ids) do
    with {:ok, data} <-
           client
           |> Tesla.post(
             "/indexes/:index_uid/documents/delete-batch",
             document_ids,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Task.cast(data)}
    end
  end
end
