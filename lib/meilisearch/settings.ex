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
    embeds_one(:typoTolerance, __MODULE__.TypeTolerence)
    embeds_one(:faceting, __MODULE__.Faceting)
    embeds_one(:pagination, __MODULE__.Pagination)
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
      :distinctAttribute
    ])
    |> Ecto.Changeset.cast_embed(:typoTolerance)
    |> Ecto.Changeset.cast_embed(:faceting)
    |> Ecto.Changeset.cast_embed(:pagination)
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
           |> Tesla.get("/indexes/:index_uid/settings",
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  defmodule Pagination do
    use TypedEctoSchema

    @primary_key false
    typed_schema "settings_pagination", null: false do
      field(:maxTotalHits, :integer)
    end

    def changeset(mod \\ %__MODULE__{}, data),
      do: Ecto.Changeset.cast(mod, data, [:maxTotalHits])

    def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end
  end

  defmodule Faceting do
    use TypedEctoSchema

    @primary_key false
    typed_schema "settings_faceting", null: false do
      field(:maxValuesPerFacet, :integer)
    end

    def changeset(mod \\ %__MODULE__{}, data),
      do: Ecto.Changeset.cast(mod, data, [:maxValuesPerFacet])

    def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end
  end

  defmodule TypeTolerence do
    use TypedEctoSchema

    @primary_key false
    typed_schema "settings_typo_tolerence", null: false do
      field(:enabled, :boolean)
      field(:disableOnWords, {:array, :string})
      field(:disableOnAttributes, {:array, :string})
      embeds_one(:minWordSizeForTypos, __MODULE__.MinWordSizesForTypos)
    end

    def changeset(mod \\ %__MODULE__{}, data) do
      mod
      |> Ecto.Changeset.cast(data, [:enabled, :disableOnWords, :disableOnAttributes])
      |> Ecto.Changeset.cast_embed(:minWordSizeForTypos)
    end

    def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end

    defmodule MinWordSizesForTypos do
      use TypedEctoSchema

      @primary_key false
      typed_schema "settings_typo_tolerence", null: false do
        field(:oneTypo, :integer)
        field(:twoTypos, :integer)
      end

      def changeset(mod \\ %__MODULE__{}, data),
        do: Ecto.Changeset.cast(mod, data, [:oneTypo, :twoTypos])

      def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

      def cast(data) when is_map(data) do
        %__MODULE__{}
        |> changeset(data)
        |> Ecto.Changeset.apply_changes()
      end
    end
  end
end
