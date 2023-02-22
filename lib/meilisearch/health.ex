defmodule Meilisearch.Health do
  @moduledoc """
  Retreive Meilisearch health status.
  """

  use Ecto.Schema

  @primary_key false
  schema "health" do
    field(:status, :string)
  end

  @type t :: %__MODULE__{
          status: String.t()
        }

  def from_json(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:status])
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  Get a response from the /health endpoint of Meilisearch.
  [meili doc](https://docs.meilisearch.com/reference/api/health.html#get-health)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Health.get(client)
      {:ok, %{status: "available"}}

  """
  @spec get(Tesla.Client.t()) :: {:ok, map()} | {:error, map()}
  def get(client) do
    with {:ok, data} <-
           client
           |> Tesla.get("/health")
           |> Meilisearch.Client.handle_response() do
      {:ok, from_json(data)}
    end
  end

  @doc """
  Check the response from the /health endpoint of Meilisearch.
  [meili doc](https://docs.meilisearch.com/reference/api/health.html#get-health)

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Health.healthy?(client)
      true

  """
  @spec healthy?(Tesla.Client.t()) :: boolean()
  def healthy?(client) do
    case get(client) do
      {:ok, %{status: "available"}} -> true
      _ -> false
    end
  end
end
