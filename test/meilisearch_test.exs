defmodule MeilisearchTest do
  use ExUnit.Case, async: true
  import Excontainers.ExUnit

  @master_key "master_key_test"

  container(
    :meili,
    MeilisearchTest.MeiliContainer.new(
      "getmeili/meilisearch:v1.0.0",
      key: @master_key
    )
  )

  defp master_opts(meili), do: [endpoint: MeilisearchTest.MeiliContainer.connection_url(meili), key: @master_key]

  test "Meilisearch manually instanciating a client", %{meili: meili} do
    health = master_opts(meili)
    |> Meilisearch.Client.new()
    |> Meilisearch.Health.get()

    assert health == {:ok, %{"status" => "available"}}
  end

  test "Meilisearch using a GenServer to retreive named client", %{meili: meili} do
    Meilisearch.start_link(:main, master_opts(meili))

    health = :main
    |> Meilisearch.client()
    |> Meilisearch.Health.get()

    assert health == {:ok, %{"status" => "available"}}
  end
end
