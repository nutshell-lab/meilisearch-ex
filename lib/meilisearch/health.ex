defmodule Meilisearch.Health do
  @moduledoc """
  Retreive Meilisearch health status.
  """

  @doc """
  Get a response from the /health endpoint of Meilisearch.

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Health.get(client)
      {:ok, %{"status" => "available"}}

  """
  def get(client) do
    case Tesla.get(client, "/health") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      _ -> :error
    end
  end


  @doc """
  Check the response from the /health endpoint of Meilisearch.

  ## Examples

      iex> client = Meilisearch.Client.new(endpoint: "http://localhost:7700", key: "master_key_test")
      iex> Meilisearch.Health.healthy?(client)
      true

  """
  def healthy?(client) do
    case get(client) do
      {:ok, %{"status" => "available"}} -> true
      _ -> false
    end
  end
end
