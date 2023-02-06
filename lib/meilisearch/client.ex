defmodule Meilisearch.Client do
  @moduledoc """
  Create an HTTP client to query Meilisearch.
  """

  @doc """
  Create a new HTTP client to query Meilisearch.

  ## Examples

      iex> Meilisearch.Client.new()
      %Tesla.Client{}

  """
  def new(opts \\ []) do
    endpoint = Keyword.get(opts, :endpoint, "")
    key = Keyword.get(opts, :key, "")
    log_level = Keyword.get(opts, :log_level, :warn)

    middleware = [
      {Tesla.Middleware.BaseUrl, endpoint},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: key},
      {Tesla.Middleware.Logger, log_level: log_level}
    ]

    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    Tesla.client(middleware, adapter)
  end
end
