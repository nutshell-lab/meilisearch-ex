defmodule Meilisearch.Index do
  @moduledoc """
  Manipulate Meilisearch indexes.
  [Index API](https://docs.meilisearch.com/reference/api/indexes.html)
  """

  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema null: false do
    field(:uid, :string)
    field(:primaryKey, :string)
    field(:createdAt, :utc_datetime)
    field(:updatedAt, :utc_datetime)
  end

  def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:uid, :primaryKey, :createdAt, :updatedAt])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  List indexes of your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#index-object)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.list(client, limit: 20, offset: 0)
      {:ok, %{offset: 0, limit: 20, total: 1, results: [%{
        uid: "movies",
        primaryKey: "id",
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00]
      }]}}

  """
  @spec list(Tesla.Client.t(), offset: integer(), limit: integer()) ::
          {:ok, Meilisearch.Pagination.t(__MODULE__.t())}
          | {:error, Meilisearch.Client.error()}
  def list(client, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Pagination.cast(data, &__MODULE__.cast/1)}
    end
  end

  @doc """
  Get an Index of your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#get-one-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.get(client, "movies")
      {:ok, %{
        uid: "movies",
        primaryKey: "id",
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec get(Tesla.Client.t(), String.t()) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def get(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes/:index_uid", opts: [path_params: [index_uid: index_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Create a new Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#create-an-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.create(client, %{uid: "movies", primaryKey: "id"})
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :indexCreation,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec create(Tesla.Client.t(), %{uid: String.t(), primaryKey: String.t() | nil}) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def create(client, params) do
    with {:ok, data} <-
           client
           |> Tesla.post("/indexes", params)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end

  @doc """
  Update an existing Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#update-an-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.update(client, "movies", %{primaryKey: "id"})
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :indexUpdate,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec update(Tesla.Client.t(), String.t(), %{primaryKey: String.t() | nil}) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def update(client, index_uid, params) do
    with {:ok, data} <-
           client
           |> Tesla.patch("/indexes/:index_uid", params,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end

  @doc """
  Delete an existing Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#delete-an-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.delete(client, "movies")
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :indexDeletion,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec delete(Tesla.Client.t(), String.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def delete(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.delete("/indexes/:index_uid", opts: [path_params: [index_uid: index_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end

  @doc """
  Create a new Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#create-an-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Index.swap(client, [%{indexes: ["movies", "actors"]}])
      {:ok, %{
        taskUid: 0,
        indexUid: nil,
        status: :enqueued,
        type: :indexSwap,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec swap(Tesla.Client.t(), list(%{indexes: list(String.t())})) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def swap(client, params) do
    with {:ok, data} <-
           client
           |> Tesla.post("/swap-indexes", params)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end
end
