defmodule Meilisearch.Task do
  @moduledoc """
  Manipulate Meilisearch tasks.
  [Task API](https://docs.meilisearch.com/reference/api/tasks.html)
  """

  use TypedEctoSchema

  @primary_key false
  typed_schema "task", null: false do
    field(:taskUid, :integer)
    field(:indexUid, :string, null: true)

    field(:status, Ecto.Enum, values: [:enqueued, :processing, :succeeded, :failed, :canceled])

    field(:type, Ecto.Enum,
      values: [
        :indexCreation,
        :indexUpdate,
        :indexDeletion,
        :indexSwap,
        :documentAdditionOrUpdate,
        :documentDeletion,
        :settingsUpdate,
        :dumpCreation,
        :taskCancelation,
        :taskDeletion,
        :snapshotCreation
      ]
    )

    field(:canceledBy, :integer, null: true)

    field(:details, :map) ::
      %{
        receivedDocuments: integer(),
        indexedDocuments: integer() | nil
      }
      | %{
          providedIds: integer(),
          deletedDocuments: integer() | nil
        }
      | %{
          primaryKey: Meilisearch.Document.document_id() | nil
        }
      | %{
          deletedDocuments: integer() | nil
        }
      | %{
          swaps: list(%{indexes: list(Meilisearch.Document.document_id())})
        }
      | %{
          rankingRules: list(String.t()),
          filterableAttributes: list(String.t()),
          distinctAttribute: String.t(),
          searchableAttributes: list(String.t()),
          displayedAttributes: list(String.t()),
          sortableAttributes: list(String.t()),
          stopWords: list(String.t()),
          synonyms: %{String.t() => list(String.t())},
          typoTolerance: %{
            enabled: boolean(),
            minWordSizeForTypos: %{
              oneTypo: integer(),
              twoTypos: integer()
            },
            disableOnWords: list(Strig.t()),
            disableOnAttributes: list(Strig.t())
          }
        }
      | %{
          dumpUid: integer() | nil
        }
      | %{
          matchedTasks: integer(),
          canceledTasks: integer() | nil,
          originalFilter: map()
        }
      | nil

    field(:error, :map) :: Meilisearch.Error.t()
    field(:duration, :string)
    field(:enqueuedAt, :utc_datetime)
    field(:startedAt, :utc_datetime)
    field(:finishedAt, :utc_datetime)
  end

  def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [
      :taskUid,
      :indexUid,
      :status,
      :type,
      :canceledBy,
      :details,
      :error,
      :duration,
      :canceledBy,
      :canceledBy,
      :startedAt,
      :finishedAt
    ])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  List tasks of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/tasks.html#get-tasks)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Task.list(client, limit: 20, offset: 0)
      {:ok, %{offset: 0, limit: 20, total: 1, results: [%{
        uid: "movies",
        primaryKey: "id",
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00]
      }]}}

  """
  @spec list(Tesla.Client.t(),
          limit: integer(),
          from: integer(),
          uids: String.t(),
          statuses: String.t(),
          types: String.t(),
          indexUids: String.t(),
          canceledBy: String.t(),
          beforeEnqueuedAt: String.t(),
          beforeStartedAt: String.t(),
          beforeFinishedAt: String.t(),
          afterEnqueuedAt: String.t(),
          afterStartedAt: String.t(),
          afterFinishedAt: String.t()
        ) ::
          {:ok, Meilisearch.PaginatedTasks.t()}
          | {:error, Meilisearch.Client.error()}
  def list(client, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.get("/tasks", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.PaginatedTasks.cast(data)}
    end
  end

  @doc """
  Get an Task of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/tasks.html#get-one-task)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Task.get(client, 32)
      {:ok, %{
        uid: 32,
        indexUid: "movies",
        status: :succeeded,
        type: :settingsUpdate,
        canceledBy: nil,
        details: {
          rankingRules: [
            "typo",
            "ranking:desc",
            "words",
            "proximity",
            "attribute",
            "exactness"
          ]
        },
        error: null,
        duration: "PT1S",
        enqueuedAt: ~U[2021-08-12 10:00:00],
        startedAt: ~U[2021-08-12 10:00:01],
        finishedAt: ~U[2021-08-12 10:02:11]
      }}

  """
  @spec get(Tesla.Client.t(), integer()) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def get(client, task_uid) do
    with {:ok, data} <-
           client
           |> Tesla.get("/tasks/:task_uid", opts: [path_params: [task_uid: task_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Cancel tasks of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/tasks.html#cancel-tasks)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Task.cancel(client, uids: "1,2")
      {:ok, %{
        taskUid: 0,
        indexUid: nil,
        status: :enqueued,
        type: :taskCancelation,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec cancel(Tesla.Client.t(),
          uids: String.t(),
          statuses: String.t(),
          types: String.t(),
          indexUids: String.t(),
          beforeEnqueuedAt: String.t(),
          beforeStartedAt: String.t(),
          beforeFinishedAt: String.t(),
          afterEnqueuedAt: String.t(),
          afterStartedAt: String.t(),
          afterFinishedAt: String.t()
        ) ::
          {:ok, Meilisearch.SummarizedTask.t()}
          | {:error, Meilisearch.Client.error()}
  def cancel(client, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.post("/tasks/cancel", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.PaginatedTasks.cast(data)}
    end
  end

  @doc """
  Delete tasks of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/tasks.html#delete-tasks)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Task.delete(client, uids: "1,2")
      {:ok, %{
        taskUid: 0,
        indexUid: nil,
        status: :enqueued,
        type: :taskDeletion,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec delete(Tesla.Client.t(),
          uids: String.t(),
          statuses: String.t(),
          types: String.t(),
          indexUids: String.t(),
          canceledBy: String.t(),
          beforeEnqueuedAt: String.t(),
          beforeStartedAt: String.t(),
          beforeFinishedAt: String.t(),
          afterEnqueuedAt: String.t(),
          afterStartedAt: String.t(),
          afterFinishedAt: String.t()
        ) ::
          {:ok, Meilisearch.SummarizedTask.t()}
          | {:error, Meilisearch.Client.error()}
  def delete(client, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.delete("/tasks", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.PaginatedTasks.cast(data)}
    end
  end
end
