defmodule Meilisearch.Task do
  @moduledoc """
  Manipulate Meilisearch tasks.
  [Task API](https://docs.meilisearch.com/reference/api/tasks.html)
  """

  use TypedEctoSchema

  @primary_key false
  typed_schema "task", null: false do
    field(:taskUid, :integer)
    field(:indexUid, :string, null: true)

    field(:status, Ecto.Enum, values: [:enqueued, :processing, :succeeded, :failed, :canceled])
    field(:type, Ecto.Enum,
      values: [
        :indexCreation,
        :indexUpdate,
        :indexDeletion,
        :indexSwap,
        :documentAdditionOrUpdate,
        :documentDeletion,
        :settingsUpdate,
        :dumpCreation,
        :taskCancelation,
        :taskDeletion,
        :snapshotCreation
      ]
    )

    field(:enqueuedAt, :naive_datetime)
  end

  def from_json(data) when is_list(data), do: Enum.map(data, &from_json(&1))

  def from_json(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:taskUid, :indexUid, :status, :type, :enqueuedAt])
    |> Ecto.Changeset.apply_changes()
  end
end
