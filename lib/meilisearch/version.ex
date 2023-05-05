defmodule Meilisearch.Version do
  @moduledoc """
  Retreive Meilisearch version.
  [Version API](https://docs.meilisearch.com/reference/api/version.html)
  """

  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema null: false do
    field(:commitSha, :string)
    field(:commitDate, :utc_datetime)
    field(:pkgVersion, :string)
  end

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:commitSha, :commitDate, :pkgVersion])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  Get a response from the /version endpoint of Meilisearch.
  [Meilisearch documentation](https://docs.meilisearch.com/reference/api/version.html#get-version-of-meilisearch)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Version.get(client)
      {:ok, %{
        commitSha: "b46889b5f0f2f8b91438a08a358ba8f05fc09fc1",
        commitDate: ~U[2019-11-15 09:51:54.27Z],
        pkgVersion: "0.1.1"
      }}

  """
  @spec get(Tesla.Client.t()) :: {:ok, __MODULE__.t()} | {:error, Meilisearch.Client.error()}
  def get(client) do
    with {:ok, data} <-
           client
           |> Tesla.get("/version")
           |> Meilisearch.Client.handle_response() do
      {:ok, cast(data)}
    end
  end
end
