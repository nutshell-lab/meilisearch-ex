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
  @spec new(
          endpoint: String.t(),
          key: String.t(),
          timeout: integer(),
          log_level: :info | :warn | :error
        ) :: Tesla.Client.t()
  def new(opts \\ []) do
    endpoint = Keyword.get(opts, :endpoint, "")
    key = Keyword.get(opts, :key, "")
    timeout = Keyword.get(opts, :timeout, 2_000)
    log_level = Keyword.get(opts, :log_level, :warn)

    middleware = [
      {Tesla.Middleware.BaseUrl, endpoint},
      Tesla.Middleware.JSON,
      Tesla.Middleware.PathParams,
      {Tesla.Middleware.BearerAuth, token: key},
      {Tesla.Middleware.Timeout, timeout: timeout},
      {Tesla.Middleware.FollowRedirects, max_redirects: 3},
      {Tesla.Middleware.Logger, log_level: log_level}
    ]

    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    Tesla.client(middleware, adapter)
  end

  def handle_response({:ok, %{status: status, body: body}})
      when status in 200..299 do
    {:ok, map_to_atom(body)}
  end

  def handle_response({:ok, %{status: status} = response})
      when status in 400..599 do
    response = Map.put(response, :body, map_to_atom(response.body))
    {:error, response}
  end

  def handle_response({:error, error}) do
    {:error, error}
  end

  def handle_response(_) do
    {:error, nil}
  end

  defp string_to_atom(value) when is_binary(value), do: String.to_atom(value)
  defp string_to_atom(value), do: value
  def map_to_atom(value) when is_map(value) do
    for {key, val} <- value, into: %{}, do: {string_to_atom(key), map_to_atom(val)}
  end
  def map_to_atom(value), do: value
end
