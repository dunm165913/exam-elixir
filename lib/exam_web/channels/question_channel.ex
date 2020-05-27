defmodule ExamWeb.QuestionChannel do
  use ExamWeb, :channel
  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  def join("question:" <> endp, payload, socket) do
    # # IO.inspect(socket)
    clas = payload["class"] || "10"
    sub = payload["subject"] || "T"
    question = ExamWeb.Cache.get("live_question_#{sub}_#{clas}")
    result_data = ExamWeb.Cache.get("live_question_#{sub}_#{clas}_result") || []

    result =
      case result_data do
        {:ok, r} -> r
        _ -> []
      end

    data =
      case question do
        {:ok, da} -> da
        _ -> nil
      end

    if authorized?(payload) do
      {:ok, %{data: %{staus: "Connected", question: data, result: result}}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    # IO.inspect("ASDadsadadssa")
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("get_question", payload, socket) do
    clas = payload["class"] || "10"
    sub = payload["subject"] || "T"
    question = ExamWeb.QuestionController.get_random()

    if question.success do
      ExamWeb.Cache.set("live_question", question.data, 120_000)

      broadcast_from!(socket, "get_question", %{
        data: Map.delete(question.data, "correct_ans"),
        success: true
      })

      push(socket, "get_question", %{data: question, success: true})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_in("live_chat", payload, socket) do
    clas = payload["class"] || "10"
    sub = payload["subject"] || "T"
    message = payload["message"]
    user_id = payload["user_info"]["id_user"]
    broadcast_from!(socket, "live_chat_#{sub}_#{clas}", %{data: payload, success: true})

    ExamWeb.MessageController.create_message(
      "live_chat_#{sub}_#{clas}",
      message,
      user_id,
      payload["user_info"]["name"] || "No name"
    )

    push(socket, "live_chat_#{sub}_#{clas}", %{data: payload, success: true})
    {:noreply, socket}
  end

  def handle_in("get_question_result", payload, socket) do
    # # IO.inspect(socket)
    clas = payload["class"] || "10"
    sub = payload["subject"] || "T"

    id_question = payload["id_question"]
    ans = payload["ans"]
    create = payload["create"]
    time = payload["time"]
    name = payload["name"]
    id = payload["id_user"]
    question = ExamWeb.Cache.get("live_question_#{sub}_#{clas}")
    # IO.inspect(question)

    result_data = ExamWeb.Cache.get("live_question_#{sub}_#{clas}_result") || []

    current_result =
      case result_data do
        {:ok, r} -> r
        _ -> []
      end

    result_existed =
      current_result
      |> Enum.find(fn r -> r.id_user == id end)

    result =
      if(result_existed == nil) do
        case question do
          {:ok, data} ->
            if ans == nil do
              %{success: false, create: create, name: name, time: time, id_user: id, ans: ans}
            else
              if data["correct_ans"] == ans do
                # save data
                result  = ExamWeb.ResultController.create_result(
                  [%{result: true, id: data["id"], your_ans: ans}],
                  data["id"] || id_question,
                  id,
                  "live_question_#{sub}_#{clas}"
                )

                ExamWeb.Cache.set(
                  "live_question_#{sub}_#{clas}_result",
                  current_result ++
                    [
                      %{
                        success: true,
                        create: create,
                        name: name,
                        time: time,
                        id_user: id,
                        ans: ans
                      }
                    ],
                  180
                )

                ExamWeb.MarkSubject.create_mark_by_question(id, "#{data["id"]}", true,  "live_question_#{sub}_#{clas}_result", result.data)

                %{success: true, create: create, name: name, time: time, id_user: id, ans: ans}
              else
                result =ExamWeb.ResultController.create_result(
                  [%{result: false, id: data["id"], your_ans: ans}],
                  data["id"] || id_question,
                  id,
                  "live_question_#{sub}_#{clas}"
                )

                ExamWeb.MarkSubject.create_mark_by_question(id, "#{data["id"]}", false,  "live_question_#{sub}_#{clas}_result",  result.data)

                ExamWeb.Cache.set(
                  "live_question_#{sub}_#{clas}_result",
                  current_result ++
                    [
                      %{
                        success: false,
                        create: create,
                        name: name,
                        time: time,
                        id_user: id,
                        ans: ans
                      }
                    ],
                  180
                )

                %{success: false, create: create, name: name, time: time, id_user: id, ans: ans}
              end
            end

          _ ->
            %{success: false, create: create, name: name, time: time, id_user: id, ans: ans}
        end
      else
        result_existed
      end

    push(socket, "get_question_result_#{sub}_#{clas}", %{data: result, success: true})
    broadcast_from!(socket, "get_question_result_#{sub}_#{clas}", %{data: result, success: true})
    {:noreply, socket}
  end

  def handle_out(event, payload, socket) do
    push(socket, event, payload)

    # send self(), :garbage_collect
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(payload) do
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

  def handle_out("get_question", payload, socket) do
    # # IO.inspect(">>>>>>>>>>>>>>>>>>>>.")
    question = ExamWeb.QuestionController.get_random()
    # # IO.inspect(question)
    {:reply, {:ok, question}, socket}
  end
end
