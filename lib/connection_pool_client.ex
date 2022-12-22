defmodule FunctionalLangs.ConnectionPoolClient do
  @pool_size 25

  def child_spec() do
    {
      Finch,
      name: __MODULE__,
      pools: %{
        "https://hacker-news.firebaseio.com" => [size: @pool_size]
      }
    }
  end

  def get_item(item_id) do
    :get
    |> Finch.build("https://hacker-news.firebaseio.com/v0/item/#{item_id}.json")
    |> Finch.request(__MODULE__)
  end
end
