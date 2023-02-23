defmodule Meilisearch.Document do
  @moduledoc """
  Manipulate Meilisearch documents.
  [Document API](https://docs.meilisearch.com/references/documents.html)
  """

  @doc """
  List documents of an index of your Meilsiearch instance.
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
          {:ok, Meilisearch.Pagination.t(map())}
          | {:error, Meilisearch.Client.error()}
  def list(client, index_uid, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes/:index_uid/documents",
             query: opts,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Pagination.from_json(data)}
    end
  end
end
