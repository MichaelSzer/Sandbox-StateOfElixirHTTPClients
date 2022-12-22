defmodule FunctionalLangs do
  @moduledoc """
  Concurrent calls to Hacker News Firebase API.
  """
  require Logger
  alias FunctionalLangs.ConnectionPoolClient, as: Client

  @words_looking ~w(wow amazing awesome always theory congrats thanks)

  def loop_until_no_new_child(children_ids, i \\ 0) do
    stream =
      Task.async_stream(
        Enum.slice(children_ids, i..-1),
        fn child_id ->
          {:ok, new_children_ids} = Client.get_comments_ids(child_id)
          new_children_ids
        end,
        max_concurrency: Client.pool_size()
      )

    all_new_children_ids = Enum.reduce(
        stream,
        [],
        fn {:ok, new_children_ids}, all_new_children_ids ->
          all_new_children_ids ++ new_children_ids
        end
      )

    #Logger.info("New comments: #{length(all_new_children_ids)}")

    if length(all_new_children_ids) > 0 do
      loop_until_no_new_child(children_ids ++ all_new_children_ids, length(children_ids))
    else
      children_ids
    end
  end

  def generate_report(post_id) do
    {:ok, request_timing_agent} = Agent.start_link(fn -> [] end)
    start_time = System.monotonic_time()
    :telemetry.attach(
      "request_timing",
      [:response, :stop],
      fn _event, %{duration: duration}, _metadata, _config ->
        Agent.update(request_timing_agent, fn timing -> [duration | timing] end)
      end,
      nil
    )

    children_ids = loop_until_no_new_child([Integer.to_string(post_id)])
    #Logger.info("Total Comments in post: ##{length(children_ids)}")
    all_comments_appearance = for child_id <- children_ids do
      text = Client.get_post_text(child_id)
        |> String.downcase()

      Map.new(@words_looking, fn word ->
        appearance = String.split(text, word)
         |> length()
        {word, appearance - 1}
      end)
    end

    Enum.reduce(all_comments_appearance, fn appearance1, appearance2 ->
      Map.merge(appearance1, appearance2, fn _, map1, map2 -> map1 + map2 end)
    end)
  end
end
