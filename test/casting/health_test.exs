defmodule MeilisearchTest.Casting.Health do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Health" do
    {:ok, json} = File.read(__DIR__ <> "/health.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Health.cast(json)

    assert %Meilisearch.Health{status: "available"} = casted
  end
end
