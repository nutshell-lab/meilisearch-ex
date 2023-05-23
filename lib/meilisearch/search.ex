defmodule Meilisearch.Search do
  @moduledoc """
  Search into your Meilisearch indexes.
  [Search API](https://docs.meilisearch.com/reference/api/search.html)
  """

  use Ecto.Schema
  @primary_key false
  embedded_schema do
    field(:hits, {:array, :map})
    field(:offset, :integer)
    field(:limit, :integer)
    field(:estimatedTotalHits, :integer)
    field(:totalHits, :integer)
    field(:totalPages, :integer)
    field(:hitsPerPage, :integer)
    field(:page, :integer)
    field(:facetDistribution, :map)
    field(:processingTimeMs, :integer)
    field(:query, :string)
  end

  @type t(item) :: %__MODULE__{
          hits: list(item),
          offset: integer(),
          limit: integer(),
          estimatedTotalHits: integer(),
          totalHits: integer(),
          totalPages: integer(),
          hitsPerPage: integer(),
          page: integer(),
          facetDistribution: map(),
          processingTimeMs: integer(),
          query: String.t()
        }

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [
      :hits,
      :offset,
      :limit,
      :estimatedTotalHits,
      :totalHits,
      :totalPages,
      :hitsPerPage,
      :page,
      :facetDistribution,
      :processingTimeMs,
      :query
    ])
    |> Ecto.Changeset.apply_changes()
  end

  @type search_params() :: %{
          q: String.t(),
          offset: integer(),
          limit: integer(),
          hitsPerPage: integer(),
          page: integer(),
          filter: String.t() | list(String.t()) | nil,
          facets: list(String.t()) | nil,
          attributesToRetrieve: list(String.t()),
          attributesToCrop: list(String.t()) | nil,
          cropLength: integer(),
          cropMarker: String.t(),
          attributesToHighlight: list(String.t()) | nil,
          highlightPreTag: String.t(),
          highlightPostTag: String.t(),
          showMatchesPosition: boolean(),
          sort: list(String.t()) | nil,
          matchingStrategy: String.t() | :last | :all
        }

  @doc """
  Search into your Meilisearch indexes using a POST request.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#get-one-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Search.search(client, "movies", q: "space")
      {:ok, %{
        offset: 0,
        limit: 20,
        estimatedTotalHits: 1,
        totalHits: 1,
        totalPages: 1,
        totalPages: 1,
        page: 1,
        facetDistribution: %{
          "genres" => %{
            "action" => 273,
            "animation" => 118,
            "adventure" => 132,
            "fantasy" => 67,
            "comedy" => 475,
            "mystery" => 70,
            "thriller" => 217
          }
        },
        processingTimeMs: 11,
        query: "space",
        hits: [%{
          "id" => 2001,
          "title" => "2001: A Space Odyssey"
        }]
      }}

  """
  @spec search(
          Tesla.Client.t(),
          String.t(),
          q: String.t(),
          offset: integer(),
          limit: integer(),
          hitsPerPage: integer(),
          page: integer(),
          filter: String.t() | list(String.t()) | nil,
          facets: list(String.t()) | nil,
          attributesToRetrieve: list(String.t()),
          attributesToCrop: list(String.t()) | nil,
          cropLength: integer(),
          cropMarker: String.t(),
          attributesToHighlight: list(String.t()) | nil,
          highlightPreTag: String.t(),
          highlightPostTag: String.t(),
          showMatchesPosition: boolean(),
          sort: list(String.t()) | nil,
          matchingStrategy: String.t() | :last | :all
        ) ::
          {:ok, __MODULE__.t(Meilisearch.Document.t())}
          | {:error, Meilisearch.Client.error()}
  def search(client, index_uid, params \\ [])

  def search(client, index_uid, params) when is_list(params),
    do: search(client, index_uid, Enum.into(params, %{}))

  def search(client, index_uid, params) when is_map(params) do
    with {:ok, data} <-
           client
           |> Tesla.post("/indexes/:index_uid/search", params,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, __MODULE__.cast(data)}
    end
  end
end
