defmodule MeilisearchTest.Casting.Version do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Version" do
    {:ok, json} = File.read(__DIR__ <> "/version.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Version.cast(json)

    assert %Meilisearch.Version{
             commitSha: "b46889b5f0f2f8b91438a08a358ba8f05fc09fc1",
             commitDate: ~U[2019-11-15 09:51:54Z],
             pkgVersion: "0.1.1"
           } = casted
  end
end
