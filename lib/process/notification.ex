defmodule ExamWeb.Notification do
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(init_arg) do
    IO.inspect("process notification")
    {:ok, init_arg}
  end

  # call create  notification to user who can do exam
  def handle_cast({:create_notification_exam, p}, state) do
    IO.inspect("df;sdafjadssa")

    ExamWeb.NotificationController.create_notification_exam(p)
    # call function create notification and send to socket

    {:noreply, state}
  end

  def handle_cast({:change_status_question, p}, state) do

    ExamWeb.NotificationController.create_notification_question(p)
    {:noreply, state}
  end



  def handle_cast(_, state) do
    IO.inspect("df;sdafjadssa111111111")

    # ExamWeb.NotificationController.create_notification_exam(p)
    # call function create notification and send to socket

    {:noreply, state}
  end
end
