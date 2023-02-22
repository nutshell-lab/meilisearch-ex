defmodule Meilisearch.Client do
  @moduledoc """
  Create a HTTP client to interact with Meilisearch APIs.

  ## Usage

  You can create a client when you needs it.

      [endpoint: "https://search.mydomain.com", key: "replace_me"]
      |> Meilisearch.Client.new()
      |> Meilisearch.Health.get()

      # %Meilisearch.Health{status: "available"}

  But you can also start a client alongside your application to access it whenever you need it.

      Meilisearch.start_link(:main, [endpoint: "https://search.mydomain.com", key: "replace_me"])
      :main
      |> Meilisearch.client()
      |> Meilisearch.Health.get()

      # %Meilisearch.Health{status: "available"}

  Within a Phoenix app you would do like this:

      defmodule MyApp.Application do
        # ...

        @impl true
        def start(_type, _args) do
          children = [
            # ...
            {Meilisearch, name: :search_admin, endpoint: "https://search.mydomain.com", key: "admin key"},
            {Meilisearch, name: :search_user, endpoint: "https://search.mydomain.com", key: "user key"}
          ]

          # ...
        end

        # ...
      end

      defmodule MyApp.MyContext do
        def create_search_index() do
          :search_admin
          |> Meilisearch.client()
          |> Meilisearch.Index.create(%{uid: "items", primaryKey: "id"})
        end

        def add_document_to_search_index(document) do
          :search_admin
          |> Meilisearch.client()
          |> Meilisearch.Document.index(document)
        end

        def search_document(query) do
          :search_user
          |> Meilisearch.client()
          |> Meilisearch.Search.search("items", %{q: query})
        end
      end
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
    {:ok, body}
  end

  def handle_response({:ok, response}) do
    {:error, Meilisearch.Error.from_response(response)}
  end

  def handle_response({:error, error}) do
    {:error, error}
  end

  def handle_response(_) do
    {:error, nil}
  end
end
