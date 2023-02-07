defmodule Meilisearch.Pagination do
  @moduledoc """
  Meilisearch paginated response.
  """

  use Ecto.Schema

  @primary_key false
  schema "pagination" do
    field(:results, {:array, :map})
    field(:offset, :integer)
    field(:limit, :integer)
    field(:total, :integer)
  end

  @type t(item) :: %__MODULE__{
          results: list(item),
          offset: integer(),
          limit: integer(),
          total: integer()
        }

  def from_json(data, load_items \\ fn x -> x end)
      when is_map(data) and is_function(load_items, 1) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:results, :offset, :limit, :total])
    |> cast_results(load_items)
    |> Ecto.Changeset.apply_changes()
  end

  defp cast_results(changeset, loader) do
    results = Ecto.Changeset.get_change(changeset, :results, [])
    results = loader.(results)
    Ecto.Changeset.put_change(changeset, :results, results)
  end
end
