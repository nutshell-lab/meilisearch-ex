defmodule Meilisearch.Key do
  @moduledoc """
  Manipulate Meilisearch api keys.
  [Key API](https://www.meilisearch.com/docs/reference/api/keys)
  """

  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema null: false do
    field(:name, :string, null: true)
    field(:description, :string, null: true)
    field(:key, :string)
    field(:uid, :string)
    field(:actions, {:array, :string})
    field(:indexes, {:array, :string})
    field(:expiresAt, :utc_datetime, null: true)
    field(:createdAt, :utc_datetime)
    field(:updatedAt, :utc_datetime)
  end

  def cast(data) when is_list(data), do: Enum.map(data, &cast(&1))

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [
      :name,
      :description,
      :key,
      :uid,
      :actions,
      :indexes,
      :expiresAt,
      :createdAt,
      :updatedAt
    ])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  List keys of your Meilisearch instance.
  [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys#get-all-keys)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Key.list(client, limit: 20, offset: 0)
      {:ok, %{offset: 0, limit: 20, total: 1, results: [%{
        name: "Default Search API Key",
        description: "Use it to search from the frontend code",
        key: "0a6e572506c52ab0bd6195921575d23092b7f0c284ab4ac86d12346c33057f99",
        uid: "74c9c733-3368-4738-bbe5-1d18a5fecb37",
        actions: ["search"],
        indexes: ["*"],
        expiresAt: nil,
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
           |> Tesla.get("/keys", query: opts)
           |> Meilisearch.Client.handle_response() do
      {:ok, Meilisearch.Pagination.cast(data, &__MODULE__.cast/1)}
    end
  end

  @doc """
  Get a Key of your Meilisearch instance.
  [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys#get-one-key)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Key.get(client, "74c9c733-3368-4738-bbe5-1d18a5fecb37")
      {:ok, %{
        name: "Default Search API Key",
        description: "Use it to search from the frontend code",
        key: "0a6e572506c52ab0bd6195921575d23092b7f0c284ab4ac86d12346c33057f99",
        uid: "74c9c733-3368-4738-bbe5-1d18a5fecb37",
        actions: ["search"],
        indexes: ["*"],
        expiresAt: nil,
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00]
      }}

  """
  @spec get(Tesla.Client.t(), String.t()) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def get(client, key_uid) do
    with {:ok, data} <-
           client
           |> Tesla.get("/keys/:key_uid", opts: [path_params: [key_uid: key_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Create a new Key in your Meilisearch instance.
  [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys#create-a-key)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Key.create(client, %{actions: ["*"], indexes: ["*"], expiresAt: nil})
      {:ok, %{
        uid: "6062abda-a5aa-4414-ac91-ecd7944c0f8d",
        key: "d0552b41536279a0ad88bd595327b96f01176a60c2243e906c52ac02375f9bc4",
        name: nil,
        description: nil,
        actions: ["*"],
        indexes: ["*"],
        expiresAt: nil,
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00],
      }}

  """
  @spec create(Tesla.Client.t(), %{
          uid: String.t() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          actions: list(String.t()),
          indexes: list(String.t()),
          expiresAt: DateTime.t() | nil
        }) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def create(client, params) do
    with {:ok, data} <-
           client
           |> Tesla.post("/keys", params)
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Update an existing Key in your Meilisearch instance.
  [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys#update-a-key)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Key.update(client, "6062abda-a5aa-4414-ac91-ecd7944c0f8d", %{name: "Products/Reviews API key", description: "Manage documents: Products/Reviews API key"})
      {:ok, %{
        uid: "6062abda-a5aa-4414-ac91-ecd7944c0f8d",
        key: "d0552b41536279a0ad88bd595327b96f01176a60c2243e906c52ac02375f9bc4",
        name: "Products/Reviews API key",
        description: "Manage documents: Products/Reviews API key",
        actions: ["*"],
        indexes: ["*"],
        expiresAt: nil,
        createdAt: ~U[2021-08-12 10:00:00],
        updatedAt: ~U[2021-08-12 10:00:00],
      }}

  """
  @spec update(Tesla.Client.t(), String.t(), %{
          name: String.t() | nil,
          description: String.t() | nil
        }) ::
          {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def update(client, key_uid, params) do
    with {:ok, data} <-
           client
           |> Tesla.patch("/keys/:key_uid", params, opts: [path_params: [key_uid: key_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end

  @doc """
  Delete an existing Index in your Meilisearch instance.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/indexes.html#delete-a-key)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Key.delete(client, "6062abda-a5aa-4414-ac91-ecd7944c0f8d")
      {:ok, nil}

  """
  @spec delete(Tesla.Client.t(), String.t()) ::
          {:ok, nil} | {:error, Meilisearch.Client.error()}
  def delete(client, key_uid) do
    with {:ok, _} <-
           client
           |> Tesla.delete("/keys/:key_uid", opts: [path_params: [key_uid: key_uid]])
           |> Meilisearch.Client.handle_response() do
      {:ok, nil}
    end
  end
end
