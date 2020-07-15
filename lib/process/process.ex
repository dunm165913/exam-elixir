defmodule ExamWeb.Process do
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(init_arg) do
    send_after(self, :start_L_12, 10000)
    send_after(self, :process_result_L_12, 102_000)

    send_after(self, :start_H_12, 10000)
    send_after(self, :process_result_H_12, 102_000)
    {:ok, init_arg}
  end

  # t_10

  def handle_info(:start_L_12, state) do
    start_L_12
    send_after(self, :start_L_12, 100_000)
    {:noreply, state}
  end

  def handle_info(:process_result_L_12, state) do
    process_result_L_12
    send_after(self, :process_result_L_12, 100_000)
    {:noreply, state}
  end

  def start_L_12() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Cache.set("live_question_L_12_result", [], 180)
    ExamWeb.QuestionController.live_question("L", "12")
  end

  def process_result_L_12() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Endpoint.broadcast!("question:live_L_12", "process_result_L_12", %{})
  end

  # t_11
  def handle_info(:start_H_12, state) do
    start_H_12
    send_after(self, :start_H_12, 100_000)
    {:noreply, state}
  end

  def handle_info(:process_result_H_12, state) do
    process_result_H_12
    send_after(self, :process_result_H_12, 100_000)
    {:noreply, state}
  end

  def start_H_12() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Cache.set("live_question_H_12_result", [], 180)
    ExamWeb.QuestionController.live_question("H", "12")
  end

  def process_result_H_12() do
    # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>")
    ExamWeb.Endpoint.broadcast!("question:live_H_12", "process_result_H_12", %{})
  end

  def send_after(pid, message, time) do
    Process.send_after(pid, message, trunc(time))
  end

  def handle_cast({:auto_check, p}, state) do
    {nubm, _} = Integer.parse("#{p["num"]}")
    time = nubm * 1.5 * 1000 * 90
    IO.inspect(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    IO.inspect(time)
    send_after(self, {:auto_check, p}, trunc(time))
    {:noreply, state}
  end

  def handle_info({:auto_check, p}, state) do
    IO.inspect(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    IO.inspect(p)
    id_ref = p["id_ref"]
    ExamWeb.ResultController.auto_check(id_ref)
    {:noreply, state}
  end

  def handle_cast({:caculator_mark_after_submit_question, p}, state) do
    ExamWeb.QuestionController.caculator_mark_after_submit_question(p)
    {:noreply, state}
  end
end
