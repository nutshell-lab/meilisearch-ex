defmodule MeilisearchTest.Casting.Search do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Search" do
    {:ok, json} = File.read(__DIR__ <> "/search.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Search.cast(json)

    assert %Meilisearch.Search{
             hits: [
               %{
                 "id" => 2770,
                 "title" => "American Pie 2",
                 "poster" => "https://image.tmdb.org/t/p/w1280/q4LNgUnRfltxzp3gf1MAGiK5LhV.jpg",
                 "overview" =>
                   "The whole gang are back and as close as ever. They decide to get even closer by spending the summer together at a beach house. They decide to hold the biggest…",
                 "release_date" => 997_405_200
               },
               %{
                 "id" => 190_859,
                 "title" => "American Sniper",
                 "poster" => "https://image.tmdb.org/t/p/w1280/svPHnYE7N5NAGO49dBmRhq0vDQ3.jpg",
                 "overview" =>
                   "U.S. Navy SEAL Chris Kyle takes his sole mission—protect his comrades—to heart and becomes one of the most lethal snipers in American history. His pinpoint accuracy not only saves countless lives but also makes him a prime…",
                 "release_date" => 1_418_256_000
               }
             ],
             offset: 0,
             limit: 20,
             estimatedTotalHits: 976,
             processingTimeMs: 35,
             query: "american "
           } = casted
  end
end
