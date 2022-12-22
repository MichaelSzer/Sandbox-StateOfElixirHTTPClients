defmodule FunctionalLangs.ConnectionPoolClient do
  def pool_size, do: 25

  def child_spec() do
    {
      Finch,
      name: __MODULE__,
      pools: %{
        "https://hacker-news.firebaseio.com" => [size: pool_size()]
      }
    }
  end

  def get_item(item_id) do
    :get
    |> Finch.build("https://hacker-news.firebaseio.com/v0/item/#{item_id}.json")
    |> Finch.request(__MODULE__)
  end

  def get_comments_ids(post_id) do
    post_id
    |> get_item()
    |> extract_children_ids()
  end

  defp extract_children_ids({:ok, %Finch.Response{body: body}}) do
    children_ids = body
      |> JSON.decode!()
      |> Map.get("kids", [])
      |> Enum.map(&(Integer.to_string(&1)))

    {:ok, children_ids}
  end

  def get_post_text(post_id) do
    post_id
    |> get_item()
    |> extract_post_text()
  end

  defp extract_post_text({:ok, %Finch.Response{body: body}}) do
    body
    |> JSON.decode!()
    |> Map.get("text", "")
  end
end
