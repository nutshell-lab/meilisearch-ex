defmodule MeilisearchTest.Casting.Task do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.Task" do
    {:ok, json} = File.read(__DIR__ <> "/task.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.Task.cast(json)

    assert %Meilisearch.Task{
             uid: 4,
             indexUid: "movie",
             status: :failed,
             type: :indexDeletion,
             canceledBy: nil,
             details: %{
               "deletedDocuments" => 0
             },
             error: %Meilisearch.Error{
               message: "Index `movie` not found.",
               code: :index_not_found,
               type: :invalid_request,
               link: "https://docs.meilisearch.com/errors#index_not_found"
             },
             duration: "PT0.001192S",
             enqueuedAt: ~U[2022-08-04T12:28:15Z],
             startedAt: ~U[2022-08-04T12:28:15Z],
             finishedAt: ~U[2022-08-04T12:28:15Z]
           } = casted
  end
end
