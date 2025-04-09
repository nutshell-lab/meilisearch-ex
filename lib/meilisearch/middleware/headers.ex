defmodule Meilisearch.Middleware.Headers do
  @moduledoc """
  Middleware for dealing with Meilisearch request headers.
  Ensures there is exactly one Content-Type: application/json header
  and adds the User-Agent header.
  """
  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, _options) do
    env
    |> Tesla.put_header("user-agent", Meilisearch.qualified_version())
    |> ensure_single_content_type()
    |> Tesla.run(next)
  end

  # Ensure there is exactly one Content-Type: application/json header
  defp ensure_single_content_type(%Tesla.Env{headers: headers} = env) do
    # Filter out all headers that are not content-type
    filtered_headers = Enum.filter(headers, fn {header, _value} -> 
      String.downcase(header) != "content-type"
    end)
    
    # Create a new environment with only non-content-type headers
    env = %{env | headers: filtered_headers}
    
    # Add a single content-type header
    Tesla.put_header(env, "content-type", "application/json")
  end
end
