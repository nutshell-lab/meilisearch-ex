defmodule Meilisearch.Settings do
  use TypedEctoSchema

  @primary_key false
  typed_schema "settings", null: false do
    field(:displayedAttributes, {:array, :string})
    field(:searchableAttributes, {:array, :string})
    field(:filterableAttributes, {:array, :string})
    field(:sortableAttributes, {:array, :string})
    field(:rankingRules, {:array, :string})
    field(:stopWords, {:array, :string})
    field(:synonyms, :map)
    field(:distinctAttribute, :string, null: true)
    field(:typoTolerance, :map)
    field(:faceting, :map)
    field(:pagination, :map)
  end

  def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [
      :displayedAttributes,
      :searchableAttributes,
      :filterableAttributes,
      :sortableAttributes,
      :rankingRules,
      :stopWords,
      :synonyms,
      :distinctAttribute,
      :typoTolerance,
      :faceting,
      :pagination
    ])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  Get all settings of an Index of your Meilsiearch instance.
  [meili doc](https://docs.meilisearch.com/reference/api/indexes.html#get-one-index)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Settings.all(client, "movies")
      {:ok, %{
        uid: "movies",
        primaryKey: "id",
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec all(Tesla.Client.t(), String.t()) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def all(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.get("/indexes/:index_uid/settings", opts: [path_params: [index_uid: index_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end
end
