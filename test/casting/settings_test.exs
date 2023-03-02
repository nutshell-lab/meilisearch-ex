defmodule MeilisearchTest.Casting.Settings do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Settings" do
    {:ok, json} = File.read(__DIR__ <> "/settings.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Settings.cast(json)

    assert %Meilisearch.Settings{
             displayedAttributes: ["*"],
             searchableAttributes: ["*"],
             filterableAttributes: [],
             sortableAttributes: [],
             rankingRules: ["words", "typo", "proximity", "attribute", "sort", "exactness"],
             stopWords: [],
             synonyms: %{},
             distinctAttribute: nil,
             typoTolerance: %{
               enabled: true,
               minWordSizeForTypos: %{
                 oneTypo: 5,
                 twoTypos: 9
               },
               disableOnWords: [],
               disableOnAttributes: []
             },
             faceting: %{
               maxValuesPerFacet: 100
             },
             pagination: %{
               maxTotalHits: 1000
             }
           } = casted
  end
end
