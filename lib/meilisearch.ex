defmodule Meilisearch do
  @moduledoc """
  A client for [MeiliSearch](https://meilisearch.com).
  The following Modules are provided for interacting with Meilisearch:
  * `Meilisearch.Client`: Create a HTTP client to interact with Meilisearch APIs.
  * `Meilisearch.Pagination`: Process paginated responses.
  * `Meilisearch.Health`: [Health API](https://docs.meilisearch.com/references/health.html)
  * `Meilisearch.Index`: [Index API](https://docs.meilisearch.com/references/indexes.html)
  * `Meilisearch.Document`: [Document API](https://docs.meilisearch.com/references/documents.html)
  * `Meilisearch.Task`: [Document API](https://docs.meilisearch.com/references/tasks.html)
  * `Meilisearch.Error`: [Errors](https://docs.meilisearch.com/reference/errors/overview.html)
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
