defmodule FunctionalLangs do
  @moduledoc """
  Concurrent calls to Hacker News Firebase API.
  """
  require Logger
  alias FunctionalLangs.ConnectionPoolClient, as: Client

  @words_looking ~w(wow amazing awesome always theory congrats thanks)

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

    {:ok, children_ids} = Client.get_comments_ids(post_id)
    for child_id <- children_ids do
      text = Client.get_post_text(child_id)
        |> String.downcase()

      Map.new(@words_looking, fn word ->
        appearance = String.split(text, word)
         |> length()
        {word, appearance - 1}
      end)
    end


  end
end
