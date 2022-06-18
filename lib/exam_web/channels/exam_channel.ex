defmodule ExamWeb.ExamChannel do
  use ExamWeb, :channel
  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  def join("exam:" <> exam_id, payload, socket) do
    if authorized?(payload) do
      {:ok, %{data: %{staus: "Connected"}}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("do_exam", payload, socket) do
    id_exam = payload["id_exam"]
    id_user = payload["id_user"]
    result = ExamWeb.ResultController.create_default(id_exam, id_user, "exam")
    IO.inspect(result)
    push(socket, "default_result", %{data: result})
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    # IO.inspect("ASDadsadadssa")
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("test", payload, socket) do
    # IO.inspect(payload)
    handle_in("shout", payload, socket)
    # {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (exam:lobby).
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", %{data: "Dsfsaddsgsfg  sdasg"})
    {:noreply, socket}
  end

  # def handle_in("do_exam", payload, socket) do
  #   id_exam = payload["id_exam"]
  #   data = get_exam(id_exam, false, 1)
  #   {:reply, %{data: data}, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(payload) do
    # IO.inspect(payload)
    case Map.has_key?(payload, "access_token") do
      true ->
        try do
          data_user =
            JsonWebToken.verify(payload["access_token"], %{
              key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
            })
        rescue
          RuntimeError -> false
        end

      false ->
        false
    end
  end

  # defp get_exam(source) do
  #   id_exam = source["id_exam"]
  #   id_user = source["id_user"]
  #   exam_query =
  #     from(e in Exam,
  #       where: e.id == ^id_exam,
  #       select: %{
  #         id: e.id,
  #         class: e.class,
  #         subject: e.subject,
  #         time: e.time,
  #         start: e.start,
  #         question: e.question,
  #         list_user_do: e.list_user_do,
  #         number_students: e.number_students,
  #         publish: e.publish
  #       }
  #     )
  #     |> Repo.one()

  #   case exam_query do
  #     nil ->
  #       %{data: %{}, status: "ID exam is incorrect", error: true, success: false}

  #     _ ->
  #       data_exam =
  #         Map.take(exam_query, [
  #           :id,
  #           :class,
  #           :subject,
  #           :time,
  #           :start,
  #           :question,
  #           :list_user_do,
  #           :number_students,
  #           :publish
  #         ])

  #       question_query =
  #         from(q in Question,
  #           where: q.id in ^data_exam.question,
  #           select: %{
  #             parent_question: q.parent_question,
  #             id: q.id,
  #             question: q.question,
  #             url_media: q.url_media,
  #             level: q.level,
  #             type: q.type,
  #             as: q.as
  #           }
  #         )

  #       question_query =
  #         if type_get do
  #           from(q in question_query, select_merge: %{correct_ans: q.correct_ans})
  #         else
  #           question_query
  #         end

  #       question_data = Repo.all(question_query)

  #       data =
  #         Map.merge(data_exam, %{
  #           question: question_data
  #         })

  #       case data_exam.publish do
  #         true ->
  #           %{data: data}

  #         false ->
  #           user_query =
  #             from(u in User,
  #               where: u.id in ^data_exam.list_user_do,
  #               select: %{
  #                 id: u.id
  #               }
  #             )
  #             |> Repo.all()
  #             |> (fn data -> data.id end)

  #           if id_user in user_query do
  #             %{data: data, success: true}
  #           else
  #             %{data: %{}, status: "You cant do the exam", success: false}
  #           end
  #       end
  #   end
  # end
end
