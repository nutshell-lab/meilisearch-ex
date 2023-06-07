defmodule MeilisearchTest.Casting.Stats do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Stats" do
    {:ok, json} = File.read(__DIR__ <> "/stats.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Stats.cast(json)

    assert %Meilisearch.Stats{
             databaseSize: 447_819_776,
             lastUpdate: ~U[2019-11-15 11:15:22Z],
             indexes: %{
               "movies" => %{
                 numberOfDocuments: 19_654,
                 isIndexing: false,
                 fieldDistribution: %{
                   "poster" => 19_654,
                   "overview" => 19_654,
                   "title" => 19_654,
                   "id" => 19_654,
                   "release_date" => 19_654
                 }
               },
               "books" => %{
                 numberOfDocuments: 5,
                 isIndexing: false,
                 fieldDistribution: %{
                   "id" => 5,
                   "title" => 5,
                   "author" => 5,
                   "price" => 5,
                   "genres" => 5
                 }
               }
             }
           } = casted
  end
end
