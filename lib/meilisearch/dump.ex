defmodule Meilisearch.Dump do
  @moduledoc """
  Manipulate Meilisearch dumps.
  [Dumps API](https://docs.meilisearch.com/reference/api/dump.html)
  """

  @doc """
  Trigger a dump creation in your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/dump.html#create-a-dump)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Dump.create(client)
      {:ok, %{
        taskUid: 0,
        indexUid: nil,
        status: :enqueued,
        type: :dumpCreation,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec create(Tesla.Client.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def create(client) do
    with {:ok, data} <-
           client
           |> Tesla.post("/dumps", %{})
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end
end
