defmodule Meilisearch.Client do
  @moduledoc """
  Create a HTTP client to interact with Meilisearch APIs.
  """

  @type error :: Meilisearch.Error.t() | Tesla.Error | nil

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

  @doc """
  Handles responses sucess and errors, returns it into a formated way.

  Meilisearch uses a limited [set of status codes](https://docs.meilisearch.com/reference/errors/overview.html#errors).
  - Sucessful ones are 200, 201, 202, 204, 205
  - Unsuccessful ones are 400, 401, 403, 404
  """
  def handle_response({:ok, %{status: status, body: body}})
      when status in 200..299 do
    {:ok, body}
  end

  def handle_response({:ok, %{status: status, body: body}}) do
    {:error, Meilisearch.Error.cast(body), status}
  end

  def handle_response({:error, error}) do
    {:error, error}
  end

  def handle_response(_) do
    {:error, nil}
  end
end
