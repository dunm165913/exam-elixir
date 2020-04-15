defmodule ExamWeb.Process do
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(init_arg) do
    # Process.send_after(self, :start_T_10, 10000)
    # Process.send_after(self, :process_result_T_10, 102_000)

    # Process.send_after(self, :start_T_11, 10000)
    # Process.send_after(self, :process_result_T_11, 102_000)
    {:ok, init_arg}
  end

  # t_10

  def handle_info(:start_T_10, state) do
    start_T_10
    Process.send_after(self, :start_T_10, 100_000)
    {:noreply, state}
  end

  def handle_info(:process_result_T_10, state) do
    process_result_T_10
    Process.send_after(self, :process_result_T_10, 100_000)
    {:noreply, state}
  end

  def start_T_10() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Cache.set("live_question_T_10_result", [], 180)
    ExamWeb.QuestionController.live_question("T", "10")
  end

  def process_result_T_10() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Endpoint.broadcast!("question:live_T_10", "process_result_T_10", %{})
  end

  # t_11
  def handle_info(:start_T_11, state) do
    start_T_11
    Process.send_after(self, :start_T_11, 100_000)
    {:noreply, state}
  end

  def handle_info(:process_result_T_11, state) do
    process_result_T_11
    Process.send_after(self, :process_result_T_11, 100_000)
    {:noreply, state}
  end

  def start_T_11() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Cache.set("live_question_T_11_result", [], 180)
    ExamWeb.QuestionController.live_question("T", "11")
  end

  def process_result_T_11() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Endpoint.broadcast!("question:live_T_11", "process_result_T_11", %{})
  end
end
