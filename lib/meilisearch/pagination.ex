defmodule Meilisearch.Pagination do
  @moduledoc """
  Represents a Meilisearch paginated response.
  """

  use Ecto.Schema
  @primary_key false
  embedded_schema do
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

  def cast(data, caster \\ fn x -> x end)
      when is_map(data) and is_function(caster, 1) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:results, :offset, :limit, :total])
    |> cast_results(caster)
    |> Ecto.Changeset.apply_changes()
  end

  defp cast_results(changeset, caster) do
    results = Ecto.Changeset.get_change(changeset, :results, [])
    Ecto.Changeset.put_change(changeset, :results, caster.(results))
  end
end
