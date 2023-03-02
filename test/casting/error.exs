defmodule MeilisearchTest.Casting.Error do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Error" do
    {:ok, json} = File.read(__DIR__ <> "/error.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Error.cast(json)

    assert %Meilisearch.Error{
             message: "Index `movies` not found.",
             code: :index_not_found,
             type: :invalid_request,
             link: "https://docs.meilisearch.com/errors#index_not_found"
           } = casted
  end
end
