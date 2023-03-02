defmodule MeilisearchTest.Casting.PaginatedTasks do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.PaginatedTasks" do
    {:ok, json} = File.read(__DIR__ <> "/paginated_tasks.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.PaginatedTasks.cast(json)

    assert %Meilisearch.PaginatedTasks{
             results: [
               %Meilisearch.Task{
                 uid: 1,
                 indexUid: "movies_reviews",
                 status: :failed,
                 type: :documentAdditionOrUpdate,
                 canceledBy: nil,
                 details: %{
                   "receivedDocuments" => 100,
                   "indexedDocuments" => 0
                 },
                 error: nil,
                 duration: nil,
                 enqueuedAt: ~U[2021-08-12T10:00:00Z],
                 startedAt: nil,
                 finishedAt: nil
               },
               %Meilisearch.Task{
                 uid: 0,
                 indexUid: "movies",
                 status: :succeeded,
                 type: :documentAdditionOrUpdate,
                 canceledBy: nil,
                 details: %{
                   "receivedDocuments" => 100,
                   "indexedDocuments" => 100
                 },
                 error: nil,
                 duration: "PT16S",
                 enqueuedAt: ~U[2021-08-11T09:25:53Z],
                 startedAt: ~U[2021-08-11T10:03:00Z],
                 finishedAt: ~U[2021-08-11T10:03:16Z]
               }
             ],
             limit: 20,
             from: 1,
             next: nil
           } = casted
  end
end
