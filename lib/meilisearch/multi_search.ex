defmodule Meilisearch.MultiSearch do
  @moduledoc """
  Search into your Meilisearch indexes.
  [Multi-Search API](https://www.meilisearch.com/docs/reference/api/multi_search)
  """

  use Ecto.Schema
  @primary_key false
  embedded_schema do
    field(:indexUid, :string)
    field(:hits, {:array, :map})
    field(:offset, :integer)
    field(:limit, :integer)
    field(:estimatedTotalHits, :integer)
    field(:totalHits, :integer)
    field(:totalPages, :integer)
    field(:hitsPerPage, :integer)
    field(:page, :integer)
    field(:facetDistribution, :map)
    field(:facetStats, :map)
    field(:processingTimeMs, :integer)
    field(:query, :string)
  end

  @type t(item) :: %__MODULE__{
          indexUid: String.t(),
          hits: list(item),
          offset: integer(),
          limit: integer(),
          estimatedTotalHits: integer(),
          totalHits: integer(),
          totalPages: integer(),
          hitsPerPage: integer(),
          page: integer(),
          facetDistribution: map(),
          facetStats: map(),
          processingTimeMs: integer(),
          query: String.t()
        }

  def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [
      :indexUid,
      :hits,
      :offset,
      :limit,
      :estimatedTotalHits,
      :totalHits,
      :totalPages,
      :hitsPerPage,
      :page,
      :facetDistribution,
      :facetStats,
      :processingTimeMs,
      :query
    ])
    |> Ecto.Changeset.apply_changes()
  end

  @type single_search_params() :: %{
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

  @type search_params() :: %{
          String.t() => single_search_params()
        }

  @doc """
  Bundle multiple search queries in a single API request. Use this endpoint to search through multiple indexes at once.
  [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/multi_search#perform-a-multi-search)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.MultiSearch.multi_search(client, %{"movies" => [q: "space"], "books" => [q: "space]})
      {:ok, [%{
        indexUid: "movies",
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
      }]}

  """
  @spec multi_search(
          Tesla.Client.t(),
          search_params()
        ) ::
          {:ok, __MODULE__.t(Meilisearch.Document.t())}
          | {:error, Meilisearch.Client.error()}
  def multi_search(client, params \\ %{})

  def multi_search(client, params) when is_list(params),
    do: multi_search(client, Enum.into(params, %{}))

  def multi_search(client, params) when is_map(params) do
    params =
      Enum.map(params, fn
        {index_uid, %{} = params} ->
          Map.put(params, :indexUid, index_uid)

        {index_uid, params} when is_list(params) ->
          Enum.into(params, %{indexUid: index_uid})
      end)

    with {:ok, %{"results" => data}} <-
           client
           |> Tesla.post("/multi-search", %{queries: params})
           |> Meilisearch.Client.handle_response() do
      {:ok, __MODULE__.cast(data)}
    end
  end
end
