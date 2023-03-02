defmodule Meilisearch do
  @moduledoc """
  A client for [MeiliSearch](https://meilisearch.com).
  The following Modules are provided for interacting with Meilisearch:
  * `Meilisearch.Client`: Create a HTTP client to interact with Meilisearch APIs.
  * `Meilisearch.Pagination`: Process paginated responses.
  * `Meilisearch.Index`: [Index API](https://docs.meilisearch.com/references/indexes.html)
  * `Meilisearch.Document`: [Document API](https://docs.meilisearch.com/references/documents.html)
  * `Meilisearch.Search`: [Search API](https://docs.meilisearch.com/references/search.html)
  * `Meilisearch.Task`: [Tasks API](https://docs.meilisearch.com/references/tasks.html)
  * `Meilisearch.Key`: [Keys API](https://docs.meilisearch.com/references/keys.html)
  * `Meilisearch.Settings`: [Settings API](https://docs.meilisearch.com/references/settings.html)
  * `Meilisearch.Stats`: [Stats API](https://docs.meilisearch.com/references/stats.html)
  * `Meilisearch.Health`: [Health API](https://docs.meilisearch.com/references/health.html)
  * `Meilisearch.Version`: [Version API](https://docs.meilisearch.com/references/version.html)
  * `Meilisearch.Dump`: [Dumps API](https://docs.meilisearch.com/references/dumps.html)
  * `Meilisearch.Error`: [Errors](https://docs.meilisearch.com/reference/errors/overview.html)

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
            {Meilisearch, name: :search_admin, endpoint: "https://search.mydomain.com", key: "key_admin"},
            {Meilisearch, name: :search_user, endpoint: "https://search.mydomain.com", key: "key_user"}
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

        def add_documents_to_search_index(documents) do
          :search_admin
          |> Meilisearch.client()
          |> Meilisearch.Document.create_or_replace("items", documents)
        end

        def search_document(query) do
          :search_user
          |> Meilisearch.client()
          |> Meilisearch.Search.search("items", %{q: query})
        end
      end
  """

  use GenServer

  defp to_name(name), do: :"__MODULE__:#{name}"

  @spec start_link(atom(),
          endpoint: String.t(),
          key: String.t(),
          timeout: integer(),
          log_level: :info | :warn | :error
        ) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(name, opts) when is_atom(name) and is_list(opts),
    do: start_link([name: name] ++ opts)

  def start_link(opts) when is_list(opts) do
    with {:ok, name} <- Keyword.fetch(opts, :name),
         name <- to_name(name) do
      GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  @impl true
  def init(opts) do
    {:ok, Meilisearch.Client.new(opts)}
  end

  @impl true
  def handle_call(:client, _, client) do
    {:reply, client, client}
  end

  @spec client(atom()) :: Tesla.Client.t()
  def client(name) do
    GenServer.call(to_name(name), :client)
  end
end
