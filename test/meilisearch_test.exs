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

  test "Meilisearch is running and healthy", %{meili: meili} do
    endpoint = MeilisearchTest.MeiliContainer.connection_url(meili)
    client = Meilisearch.Client.new(endpoint: endpoint, key: @master_key)

    healthy = Meilisearch.Health.healthy?(client)
    assert healthy == true
  end
end
