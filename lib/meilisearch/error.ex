defmodule Meilisearch.Error do
  @moduledoc """
  Represents a Meilisearch error.
  [Errors](https://www.meilisearch.com/docs/reference/errors/overview)
  """

  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema null: false do
    field(:message, :string)
    field(:link, :string)

    field(:type, Ecto.Enum,
      values: [
        :invalid_request,
        :internal,
        :auth,
        :system
      ]
    )

    # see https://www.meilisearch.com/docs/reference/errors/error_codes
    field(:code, Ecto.Enum,
      values: [
        :api_key_already_exists,
        :api_key_not_found,
        :bad_request,
        :database_size_limit_reached,
        :document_fields_limit_reached,
        :document_not_found,
        :dump_process_failed,
        :immutable_api_key_actions,
        :immutable_api_key_created_at,
        :immutable_api_key_expires_at,
        :immutable_api_key_indexes,
        :immutable_api_key_key,
        :immutable_api_key_uid,
        :immutable_api_key_updated_at,
        :immutable_index_uid,
        :immutable_index_updated_at,
        :index_already_exists,
        :index_creation_failed,
        :index_not_found,
        :index_primary_key_already_exists,
        :index_primary_key_multiple_candidates_found,
        :internal,
        :invalid_api_key,
        :invalid_api_key_actions,
        :invalid_api_key_description,
        :invalid_api_key_expires_at,
        :invalid_api_key_indexes,
        :invalid_api_key_limit,
        :invalid_api_key_name,
        :invalid_api_key_offset,
        :invalid_api_key_uid,
        :invalid_content_type,
        :invalid_document_id,
        :invalid_document_fields,
        :invalid_document_limit,
        :invalid_document_offset,
        :invalid_document_geo_field,
        :invalid_index_limit,
        :invalid_index_offset,
        :invalid_index_uid,
        :invalid_index_primary_key,
        :invalid_search_attributes_to_crop,
        :invalid_search_attributes_to_highlight,
        :invalid_search_attributes_to_retrieve,
        :invalid_search_crop_length,
        :invalid_search_crop_marker,
        :invalid_search_facets,
        :invalid_search_filter,
        :invalid_search_highlight_post_tag,
        :invalid_search_highlight_pre_tag,
        :invalid_search_hits_per_page,
        :invalid_search_limit,
        :invalid_search_matching_strategy,
        :invalid_search_offset,
        :invalid_search_page,
        :invalid_search_q,
        :invalid_search_show_matches_position,
        :invalid_search_sort,
        :invalid_settings_displayed_attributes,
        :invalid_settings_distinct_attribute,
        :invalid_settings_faceting,
        :invalid_settings_filterable_attributes,
        :invalid_settings_pagination,
        :invalid_settings_ranking_rules,
        :invalid_settings_searchable_attributes,
        :invalid_settings_sortable_attributes,
        :invalid_settings_stop_words,
        :invalid_settings_synonyms,
        :invalid_settings_typo_tolerance,
        :invalid_state,
        :invalid_store_file,
        :invalid_swap_duplicate_index_found,
        :invalid_swap_indexes,
        :invalid_task_after_enqueued_at,
        :invalid_task_after_finished_at,
        :invalid_task_after_started_at,
        :invalid_task_before_enqueued_at,
        :invalid_task_before_finished_at,
        :invalid_task_before_started_at,
        :invalid_task_canceled_by,
        :invalid_task_index_uids,
        :invalid_task_limit,
        :invalid_task_statuses,
        :invalid_task_types,
        :invalid_task_uids,
        :io_error,
        :index_primary_key_no_candidate_found,
        :malformed_payload,
        :missing_api_key_actions,
        :missing_api_key_expires_at,
        :missing_api_key_indexes,
        :missing_authorization_header,
        :missing_content_type,
        :missing_document_id,
        :missing_index_uid,
        :missing_master_key,
        :missing_payload,
        :missing_swap_indexes,
        :missing_task_filters,
        :no_space_left_on_device,
        :not_found,
        :payload_too_large,
        :task_not_found,
        :too_many_open_files,
        :unretrievable_document
      ]
    )
  end

  def cast(data) when is_nil(data), do: nil

  def cast(data) when is_map(data) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(data, [:message, :link, :type, :code])
    |> Ecto.Changeset.apply_changes()
  end
end
