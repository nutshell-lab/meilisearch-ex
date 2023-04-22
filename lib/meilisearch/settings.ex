defmodule Meilisearch.Settings do
  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema null: false do
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
  Get settings of an Index of your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-settings)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Settings.get(client, "movies")
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
           |> Tesla.get("/indexes/:index_uid/settings",
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Update settings of an Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-settings)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Settings.update(client, "movies", %{displayedAttributes: ["title"]})
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :settingsUpdate,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec update(Tesla.Client.t(), String.t(), __MODULE__.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def update(client, index_uid, params) do
    with {:ok, data} <-
           client
           |> Tesla.patch("/indexes/:index_uid/settings", params,
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end

  @doc """
  Reset settings of an Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#reset-settings)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Settings.reset(client, "movies")
      {:ok, %{
        taskUid: 0,
        indexUid: "movies",
        status: :enqueued,
        type: :settingsUpdate,
        enqueuedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec reset(Tesla.Client.t(), String.t()) ::
          {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
  def reset(client, index_uid) do
    with {:ok, data} <-
           client
           |> Tesla.delete("/indexes/:index_uid/settings",
             opts: [path_params: [index_uid: index_uid]]
           )
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.SummarizedTask.cast(data)}
    end
  end

  defmodule DisplayedAttributes do
    @doc """
    Get displayed attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-displayed-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DisplayedAttributes.get(client, "movies")
        {:ok, ["title", "overview", "genres", "release_date.year"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/displayed-attributes",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update displayed attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-displayed-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DisplayedAttributes.update(client, "movies", ["title", "overview", "genres", "release_date"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/displayed-attributes", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset displayed attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-displayed-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DisplayedAttributes.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/displayed-attributes",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule SearchableAttributes do
    @doc """
    Get searchable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-searchable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SearchableAttributes.get(client, "movies")
        {:ok, ["title", "overview", "genres", "release_date.year"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/searchable-attributes",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update searchable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-searchable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SearchableAttributes.update(client, "movies", ["title", "overview", "genres"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/searchable-attributes", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset searchable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-searchable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SearchableAttributes.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/searchable-attributes",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule FilterableAttributes do
    @doc """
    Get filterable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-filterable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.FilterableAttributes.get(client, "movies")
        {:ok, ["genres", "director", "release_date.year"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/filterable-attributes",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update filterable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-filterable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.FilterableAttributes.update(client, "movies", ["genres", "director"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/filterable-attributes", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset filterable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-filterable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.FilterableAttributes.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/filterable-attributes",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule SortableAttributes do
    @doc """
    Get sortable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-sortable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SortableAttributes.get(client, "movies")
        {:ok, ["price", "author.surname"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/sortable-attributes",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update sortable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-sortable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SortableAttributes.update(client, "movies", ["price", "author"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/sortable-attributes", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset sortable attributes settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-sortable-attributes)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.SortableAttributes.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/sortable-attributes",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule RankingRules do
    @doc """
    Get ranking rules settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-ranking-rules)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.RankingRules.get(client, "movies")
        {:ok, ["words", "typo", "proximity", "attribute", "sort", "exactness"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/ranking-rules",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update ranking rules settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-ranking-rules)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.RankingRules.update(client, "movies", ["words", "typo", "proximity", "attribute", "sort", "exactness", "release_date:desc"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/ranking-rules", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset ranking rules settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-ranking-rules)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.RankingRules.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/ranking-rules",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule StopWords do
    @doc """
    Get stop words settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-stop-words)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.StopWords.get(client, "movies")
        {:ok, ["of", "the", "to"]}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, list(String.t())} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/stop-words",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update stop words settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-stop-words)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.StopWords.update(client, "movies", ["of", "the", "to"])
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), list(String.t())) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/stop-words", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset stop words settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-stop-words)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.StopWords.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/stop-words",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule Synonyms do
    @doc """
    Get synonyms settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-synonyms)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Synonyms.get(client, "movies")
        {:ok, %{
          "wolverine" => ["xmen", "logan"],
          "logan" => ["wolverine", "xmen"],
          "wow" => ["world of warcraft"]
        }}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, %{String.t() => list(String.t())}} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/synonyms",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update synonyms settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-synonyms)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Synonyms.update(client, "movies", %{
          "wolverine" => ["xmen", "logan"],
          "logan" => ["wolverine", "xmen"],
          "wow" => ["world of warcraft"]
        })
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), %{String.t() => list(String.t())}) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.put("/indexes/:index_uid/settings/synonyms", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset synonyms settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-synonyms)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Synonyms.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/synonyms",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule DistinctAttributes do
    @doc """
    Get distinct attribute settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-distinct-attribute)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DistinctAttributes.get(client, "movies")
        {:ok, "skuid"}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, String.t()} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      client
      |> Tesla.get("/indexes/:index_uid/settings/distinct-attribute",
        opts: [path_params: [index_uid: index_uid]]
      )
      |> Meilisearch.Client.handle_response()
    end

    @doc """
    Update distinct attribute settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-distinct-attribute)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DistinctAttributes.update(client, "movies", "skuid")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             # Tesla encodes "uuid" to uuid instead of "\"uuid\""
             |> Tesla.put(
               "/indexes/:index_uid/settings/distinct-attribute",
               params |> Jason.encode!(),
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset distinct attribute settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-distinct-attribute)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.DistinctAttributes.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/distinct-attribute",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule Faceting do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema null: false do
      field(:maxValuesPerFacet, :integer)
    end

    def changeset(mod \\ %__MODULE__{}, data),
      do: Ecto.Changeset.cast(mod, data, [:maxValuesPerFacet])

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end

    @doc """
    Get faceting settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-faceting-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Faceting.get(client, "movies")
        {:ok, %Meilisearch.Settings.Faceting{maxValuesPerFacet: 100}}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.get("/indexes/:index_uid/settings/faceting",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, __MODULE__.cast(data)}
      end
    end

    @doc """
    Update faceting settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-faceting-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Faceting.update(client, "movies", %{maxValuesPerFacet: 2})
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), %{maxValuesPerFacet: integer()}) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.patch("/indexes/:index_uid/settings/faceting", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset faceting settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#reset-faceting-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Faceting.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/faceting",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule Pagination do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema null: false do
      field(:maxTotalHits, :integer)
    end

    def changeset(mod \\ %__MODULE__{}, data),
      do: Ecto.Changeset.cast(mod, data, [:maxTotalHits])

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end

    @doc """
    Get pagination settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-pagination-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Pagination.get(client, "movies")
        {:ok, %Meilisearch.Settings.Pagination{maxTotalHits: 1000}}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.get("/indexes/:index_uid/settings/pagination",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, __MODULE__.cast(data)}
      end
    end

    @doc """
    Update pagination settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-pagination-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Pagination.update(client, "movies", %{maxTotalHits: 100})
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), %{maxTotalHits: integer()}) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.patch("/indexes/:index_uid/settings/pagination", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset pagination settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#reset-pagination-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.Pagination.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/pagination",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end
  end

  defmodule TypeTolerence do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema null: false do
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

    def cast(data) when is_map(data) do
      %__MODULE__{}
      |> changeset(data)
      |> Ecto.Changeset.apply_changes()
    end

    @doc """
    Get typo tolerance settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#get-typo-tolerance-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.TypoTolerance.get(client, "movies")
        {:ok, %Meilisearch.Settings.TypoTolerance{
          enabled: true,
          disableOnWords: [],
          disableOnAttributes: [],
          minWordSizeForTypos: %Meilisearch.Settings.TypoTolerance.MinWordSizesForTypos{
            oneTypo: 5,
            twoTypos: 9
          }
        }}

    """
    @spec get(Tesla.Client.t(), String.t()) ::
            {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
    def get(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.get("/indexes/:index_uid/settings/typo-tolerance",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, __MODULE__.cast(data)}
      end
    end

    @doc """
    Update typo tolerance settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#update-typo-tolerance-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.TypoTolerance.update(client, "movies", %{maxTotalHits: 100})
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec update(Tesla.Client.t(), String.t(), %{
            enabled: boolean(),
            disableOnWords: list(String.t()),
            disableOnAttributes: list(String.t()),
            minWordSizeForTypos: %{
              oneTypo: integer(),
              twoTypos: integer()
            }
          }) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def update(client, index_uid, params) do
      with {:ok, data} <-
             client
             |> Tesla.patch("/indexes/:index_uid/settings/typo-tolerance", params,
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    @doc """
    Reset typo tolerance settings of an Index of your Meilisearch instance.
    [Meilisearch documentation](https://docs.meilisearch.com/reference/api/settings.html#reset-typo-tolerance-settings)

    ## Examples

        iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
        iex> Meilisearch.Settings.TypoTolerance.reset(client, "movies")
        {:ok, %{
          taskUid: 0,
          indexUid: "movies",
          status: :enqueued,
          type: :settingsUpdate,
          enqueuedAt: ~U[2021-08-12 10:00:00]
        }}

    """
    @spec reset(Tesla.Client.t(), String.t()) ::
            {:ok, Meilisearch.SummarizedTask.t()} | {:error, Meilisearch.Client.error()}
    def reset(client, index_uid) do
      with {:ok, data} <-
             client
             |> Tesla.delete("/indexes/:index_uid/settings/typo-tolerance",
               opts: [path_params: [index_uid: index_uid]]
             )
             |> Meilisearch.Client.handle_response() do
        {:ok, Meilisearch.SummarizedTask.cast(data)}
      end
    end

    defmodule MinWordSizesForTypos do
      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema null: false do
        field(:oneTypo, :integer)
        field(:twoTypos, :integer)
      end

      def changeset(mod \\ %__MODULE__{}, data),
        do: Ecto.Changeset.cast(mod, data, [:oneTypo, :twoTypos])

      def cast(data) when is_map(data) do
        %__MODULE__{}
        |> changeset(data)
        |> Ecto.Changeset.apply_changes()
      end
    end
  end
end
