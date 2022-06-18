defmodule ExamWeb.StatisticController do
  use ExamWeb, :controller
  plug(Exam.Plugs.Auth)
  import Ecto.Query, only: [from: 2]
end
