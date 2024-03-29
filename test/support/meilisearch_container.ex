defmodule MeilisearchTest.MeiliContainer do
  @moduledoc """
  Functions to build and interact with Redis containers.
  """

  alias Docker.CommandWaitStrategy
  alias Excontainers.Container

  @port 7700

  @doc """
  Creates a Meilisearch container.
  """
  def new(image, opts \\ []) do
    Docker.Container.new(
      image,
      exposed_ports: [@port],
      environment: %{
        MEILI_MASTER_KEY: Keyword.get(opts, :key, "master_test_key")
      },
      wait_strategy: wait_strategy()
    )
  end

  @doc """
  Returns the port on the _host machine_ where the Meilisearch container is listening.
  """
  def port(pid), do: with({:ok, port} <- Container.mapped_port(pid, @port), do: port)

  @doc """
  Returns the endpoint of Meilisearch from the the _host machine_ pov.
  """
  def connection_url(pid), do: "http://localhost:#{port(pid)}/"

  defp wait_strategy do
    CommandWaitStrategy.new([
      "sh",
      "-c",
      "curl http://0.0.0.0:7700/health | grep 'available'"
    ])
  end
end
