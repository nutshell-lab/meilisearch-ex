defmodule Meilisearch.Stats do
  @moduledoc """
  Get Stats about your Meilisearch indexes.
  [Key API](https://docs.meilisearch.com/reference/api/stats.html)
  """

  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema do
    field(:databaseSize, :integer)
    field(:lastUpdate, :utc_datetime)
    field(:indexes, :map) :: %{String.t() => Meilisearch.Stats.Stat.t()}
  end

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:databaseSize, :lastUpdate, :indexes])
    |> cast_indexes()
    |> Ecto.Changeset.apply_changes()
  end

  defp cast_indexes(changeset) do
    indexes =
      changeset
      |> Ecto.Changeset.get_change(:indexes, %{})
      |> Enum.map(fn {k, v} -> {k, Meilisearch.Stats.Stat.cast(v)} end)
      |> Enum.into(%{})

    Ecto.Changeset.put_change(changeset, :indexes, indexes)
  end

  @doc """
  Get stats about all indexes of your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/stats.html#get-stats-of-all-indexes)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Stats.all(client)
      {:ok, %{
        databaseSize: 447819776,
        lastUpdate: ~U[2021-08-12 10:00:00],
        indexes: %{
          "movies" => %{
            numberOfDocuments: 19654,
            isIndexing: false,
            fieldDistribution: %{
              "poster" => 19654,
              "overview" => 19654,
              "title" => 19654,
              "id" => 19654,
              "release_date" => 19654
            }
          },
          "books" => %{
            numberOfDocuments: 5,
            isIndexing: false,
            fieldDistribution: %{
              "id" => 5,
              "title" => 5,
              "author" => 5,
              "price" => 5,
              "genres" => 5
            }
          }
        }
      }}

  """
  @spec all(Tesla.Client.t(), offset: integer(), limit: integer()) ::
          {:ok, __MODULE__.t()}
          | {:error, Meilisearch.Client.error()}
  def all(client, opts \\ []) do
    with {:ok, data} <-
           client
           |> Tesla.get("/stats", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Get stats about a specific index of your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/stats.html#get-stats-of-an-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Stats.get(client, "movies")
      {:ok, %{
        numberOfDocuments: 19654,
        isIndexing: false,
        fieldDistribution: &{
          "poster" => 19654,
          "release_date" => 19654,
          "title" => 19654,
          "id" => 19654,
          "overview" => 19654
        }
      }}

  """
  @spec get(Tesla.Client.t(), String.t()) ::
          {:ok, Meilisearch.Stats.Stat.t()} | {:error, Meilisearch.Client.error()}
  def get(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes/:index_uid/stats", opts: [path_params: [index_uid: index_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Stats.Stat.cast(data)}
    end
  end

  defmodule Stat do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      field(:numberOfDocuments, :integer)
      field(:isIndexing, :boolean)
      field(:fieldDistribution, :map) :: %{String.t() => integer()}
    end

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> Ecto.Changeset.cast(data, [:numberOfDocuments, :isIndexing, :fieldDistribution])
      |> Ecto.Changeset.apply_changes()
    end
  end
end
