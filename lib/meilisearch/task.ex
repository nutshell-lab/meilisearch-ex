defmodule Meilisearch.Task do
  @moduledoc """
  Retreive Meilisearch health status.
  """

  use Ecto.Schema

  schema "tasks" do
    field(:taskUid, :integer)
    field(:indexUid, :string)
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

  @type t :: %__MODULE__{
          taskUid: integer(),
          indexUid: String.t(),
          status: :enqueued | :processing | :succeeded | :failed | :canceled,
          type:
            :indexCreation
            | :indexUpdate
            | :indexDeletion
            | :indexSwap
            | :documentAdditionOrUpdate
            | :documentDeletion
            | :settingsUpdate
            | :dumpCreation
            | :taskCancelation
            | :taskDeletion
            | :snapshotCreation,
          enqueuedAt: DateTime.t()
        }

  def from_json(data) when is_list(data), do: Enum.map(data, &from_json(&1))

  def from_json(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:taskUid, :indexUid, :status, :type, :enqueuedAt])
    |> Ecto.Changeset.apply_changes()
  end
end
