defmodule MeilisearchTest.Casting.Key do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Key" do
    {:ok, json} = File.read(__DIR__ <> "/key.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Key.cast(json)

    assert %Meilisearch.Key{
      name: "Default Search API Key",
      description: "Use it to search from the frontend code",
      key: "0a6e572506c52ab0bd6195921575d23092b7f0c284ab4ac86d12346c33057f99",
      uid: "74c9c733-3368-4738-bbe5-1d18a5fecb37",
      actions: ["search"],
      indexes: ["*"],
      expiresAt: nil,
      createdAt: ~U[2021-08-11T10:00:00Z],
      updatedAt: ~U[2021-08-11T10:00:00Z]
    } = casted
  end
end
