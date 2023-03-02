defmodule MeilisearchTest.Casting.Index do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Index" do
    {:ok, json} = File.read(__DIR__ <> "/index.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Index.cast(json)

    assert %Meilisearch.Index{
             uid: "movies",
             createdAt: ~U[2022-02-10T07:45:15Z],
             updatedAt: ~U[2022-02-21T15:28:43Z],
             primaryKey: "id"
           } = casted
  end
end
