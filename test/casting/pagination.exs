defmodule MeilisearchTest.Casting.Pagination do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Pagination" do
    {:ok, json} = File.read(__DIR__ <> "/pagination.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Pagination.cast(json, &Meilisearch.Index.cast/1)

    assert %Meilisearch.Pagination{
             results: [
               %Meilisearch.Index{
                 uid: "books",
                 createdAt: ~U[2022-03-08 10:00:27Z],
                 updatedAt: ~U[2022-03-08 10:00:27Z],
                 primaryKey: "id"
               },
               %Meilisearch.Index{
                 uid: "meteorites",
                 createdAt: ~U[2022-03-08T10:00:44Z],
                 updatedAt: ~U[2022-03-08T10:00:44Z],
                 primaryKey: "id"
               },
               %Meilisearch.Index{
                 uid: "movies",
                 createdAt: ~U[2022-02-10T07:45:15Z],
                 updatedAt: ~U[2022-02-21T15:28:43Z],
                 primaryKey: "id"
               }
             ],
             offset: 0,
             limit: 3,
             total: 5
           } = casted
  end
end
