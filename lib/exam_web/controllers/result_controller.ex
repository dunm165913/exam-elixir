defmodule ExamWeb.ResultController do
  use ExamWeb, :controller

  import Ecto.Query, only: [from: 2]
  plug(Exam.Plugs.Auth)   
  alias Exam.Result


  def get_result(conn, params) do
    id_user = conn.assigns.user.user_id
    id_exam = params["id_exam"]
    IO.inspect(id_user)
    IO.inspect(id_exam)
    result = from(r in Result,
      where: r.user_id == ^id_user and r.exam_id == ^id_exam,
      select: %{
        id: r.id,
        result: r.result,
        exam_id: r.exam_id,
        user_id: r.user_id,
        create_at: r.inserted_at
      })
    |> Repo.all
     
    IO.inspect(result)
    json(conn, %{data: result, status: "OK", success: true})
  end
end