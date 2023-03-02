defmodule MeilisearchTest.Casting.SummarizedSummarizedTask do
  use ExUnit.Case, async: true

  test "Cast Meilisearch.SummarizedTask" do
    {:ok, json} = File.read(__DIR__ <> "/summarized_task.json")
    {:ok, json} = Jason.decode(json)
    casted = Meilisearch.SummarizedTask.cast(json)

    assert %Meilisearch.SummarizedTask{
      taskUid: 4,
      indexUid: "movie",
      status: :failed,
      type: :indexDeletion,
      enqueuedAt: ~U[2022-08-04T12:28:15Z]
    } = casted
  end
end
