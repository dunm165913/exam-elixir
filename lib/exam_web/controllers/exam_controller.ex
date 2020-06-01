defmodule ExamWeb.ExamController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  plug(
    Exam.Plugs.Auth
    when action in [
           :index,
           :check_result,
           :change_user,
           :change_question,
           :get_intro,
           :create,
           :my_exam,
           :get_info,
           :update_exam
         ]
  )

  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  @spec index(Plug.Conn.t(), nil | keyword | map) :: Plug.Conn.t()
  def index(conn, parmas) do
    id_exam = parmas["id"]
    # IO.inspect(parmas)
    id_user = conn.assigns.user.user_id

    case id_exam do
      nil ->
        json(conn, %{data: %{}, status: "No id exam", success: false})

      _ ->
        data = get_exam(id_exam, false, id_user)

        if data.success do
          re = ExamWeb.ResultController.create_default(id_exam, id_user, "exam")

          if re.success do
            data =
              data
              |> Map.put("result", re.data)

            json(conn, %{data: data, success: true})
          else
            json(conn, %{data: %{}, message: "error create default", success: false})
          end
        else
          json(conn, %{data: %{}, message: "can do exam", success: false})
        end
    end
  end

  def options(conn, params) do
    json(conn, %{})
  end

  def create(conn, params) do
    data = params["data"] || %{}
    id_user = conn.assigns.user.user_id

    user = Repo.get(User, id_user)
    IO.inspect(user.role)

    # roll == admiin => exam must be published and type's exam is exam
    # if roll != admin => type's exam is custom exam and

    result =
      case user.role do
        "admin" ->
          Exam.changeset(
            %Exam{},
            Map.merge(data, %{"user_id" => id_user, "publish" => true, "type_exam" => "exam"})
          )

        _ ->
          Exam.changeset(
            %Exam{},
            Map.merge(data, %{"user_id" => id_user, "type_exam" => "custom_exam"})
          )
      end
      |> Repo.insert()

    case result do
      {:ok, d} ->
        {:ok, j} =
          d
          |> Map.drop([:__meta__])
          |> Poison.encode()

        j =
          j
          |> Poison.decode!()

        listU =
          j["list_user_do"]
          |> Enum.map(fn x ->
            GenServer.cast(
              ExamWeb.Notification,
              {:create_notification_exam,
               %{
                 "from" => %{"source" => "De thi #{j["id"]}", "exam" => j["id"]},
                 "to" => x,
                 "media" => %{},
                 "data" => %{"message" => "Ban duoc moi tham gia lam bai thi"},
                 "actions" => %{"url" => "/exam/#{j["id"]}/intro"},
                 "setting" => %{}
               }}
            )
          end)

        send_noti(j["list_user_do"] || [], j)
        json(conn, %{data: j, success: true})

      # send Notification to User who can do

      {:error, c} ->
        IO.inspect(c)
        json(conn, %{data: %{}, success: false, message: "Kieem tra lai thong tin"})
    end
  end

  def send_noti(listU, exam) do
    listU
    |> Enum.map(fn x ->
      GenServer.cast(
        ExamWeb.Notification,
        {:create_notification_exam,
         %{
           "from" => %{"source" => "De thi #{exam["id"]}", "exam" => exam["id"]},
           "to" => x,
           "media" => %{},
           "data" => %{"message" => "Ban duoc moi tham gia lam bai thi"},
           "actions" => [],
           "setting" => %{}
         }}
      )
    end)
  end

  @spec check_result_data(any, any, any, any, any) :: %{
          data: any,
          status: <<_::16, _::_*128>>,
          success: boolean
        }
  def check_result_data(client_ans, id_exam, id_user, id_ref, source) do
    data = get_exam(id_exam, true, id_user)

    case Map.has_key?(data, :error) do
      true ->
        %{data: %{}, status: "Exam isn't existed", success: false}

      false ->
        result =
          Enum.reduce(data.data.question, [], fn d, acc ->
            if d.correct_ans == client_ans["#{d.id}"] do
              acc ++
                [
                  %{
                    id: d.id,
                    result: true,
                    your_ans: client_ans["#{d.id}"]
                  }
                ]
            else
              acc ++
                [
                  %{
                    id: d.id,
                    result: false,
                    your_ans: client_ans["#{d.id}"]
                  }
                ]
            end
          end)

        # # IO.inspect(result)
        # save result

        current_result = Repo.get!(Result, id_ref)
        setting = current_result.setting

        has_protect_mark =
          if data.type_exam == "custom_exam" do
            true
          else
            if Map.has_key?(setting, "protect_mark") do
              setting["protect_mark"]
            else
              false
            end
          end

        changeset =
          Result.changeset(current_result, %{
            "result" => result,
            "id_ref" => "#{id_exam}",
            "user_id" => id_user,
            "source" => source,
            "status" => "done"
          })

        # save to mark_subject if no protect mark
        if !has_protect_mark do
          coefficient =
            case current_result.setting["n-th"] do
              1 -> 1
              2 -> 0.85
              3 -> 0.7
              _ -> 0.6
            end

          r =
            ExamWeb.MarkSubject.create_mark_by_result_exam(
              id_user,
              "#{id_exam}",
              result,
              data.data.subject,
              data.data.class,
              id_ref,
              coefficient
            )

          IO.inspect(r)
        end

        result_t = Repo.update(changeset)
        %{data: result, status: "ok", success: true}
    end
  end

  def check_result(conn, parmas) do
    client_ans = parmas["ans"]
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id
    id_ref = parmas["id_ref"]
    source = parmas["source"] || "exam"
    data = get_exam(id_exam, true, id_user)

    result = check_result_data(client_ans, id_exam, id_user, id_ref, "exam")

    json(conn, result)
  end

  def update_exam(conn, p) do
    id_user = conn.assigns.user.user_id
    id_e = p["data"]["id"] || 0
    IO.inspect(id_e)

    e =
      from(e in Exam,
        where: e.id == ^id_e and e.user_id == ^id_user and e.type_exam == "custom_exam"
      )
      |> Repo.one()

    IO.inspect(e)

    case e do
      nil ->
        json(conn, %{data: %{}, message: "Not found exam", success: false})

      _ ->
        result =
          Exam.changeset(e, Map.merge(p["data"], %{"type_exam" => "custom_exam"}))
          |> Repo.update()

        case result do
          {:ok, s} ->
            IO.inspect(s)
            json(conn, %{data: %{}, success: true})

          {:error, f} ->
            IO.inspect(f)
            json(conn, %{data: %{}, success: false, message: "Check your info"})
        end
    end
  end

  def check_is_creator(conn, p) do
    id_e = p["id"]
    token = p["token"]

    result = check_is_creator_exam(token, id_e)
    json(conn, result)
  end

  def check_is_creator_exam(token, id_e) do
    u =
      try do
        JsonWebToken.verify(token, %{
          key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
        })
      rescue
        RuntimeError -> nil
      end

    result =
      case u do
        {:error, h} ->
          %{success: false}

        {:ok, us} ->
          e =
            from(e in Exam,
              where: e.id == ^id_e and e.user_id == ^us.user_id and e.type_exam == "custom_exam"
            )
            |> Repo.one()

          case e do
            nil -> %{success: false}
            _ -> %{success: true}
          end
      end
  end

  def statistic(conn, p) do
    token = p["access_token"]
    id_e = p["id"]
    is_owner = check_is_creator_exam(token, id_e)

    if(is_owner.success) do
      data = ExamWeb.ResultController.get_statistic_exam(id_e)
      # need filter by User
      exam = Repo.get(Exam, id_e)

      json(conn, data)
    else
      json(conn, %{
        data: %{},
        success: false,
        message: "Yo dont have enough permission to do this action"
      })
    end
  end

  # @spec get_exam(any, any, any) :: %{
  #         :data => %{optional(:publish) => boolean},
  #         optional(:error) => true,
  #         optional(:status) => <<_::160>>,
  #         optional(:success) => boolean
  #       }
  # def get_exam_v2(id_exam, id_user) do

  #   exam =
  #     from(e in Exam,
  #       where: e.id == ^id_exam,
  #       preload: (question_d: q)
  #     )
  #     |> Repo.one()

  #   IO.inspect(exam)
  # end

  def get_intro(conn, parmas) do
    id_exam = parmas["id_exam"]

    id_user = conn.assigns.user.user_id

    exam =
      from(e in Exam,
        where: e.id == ^id_exam,
        select: %{
          id: e.id,
          class: e.class,
          subject: e.subject,
          time: e.time,
          start: e.start,
          question: e.question,
          list_user_do: e.list_user_do,
          number_students: e.number_students,
          publish: e.publish
        }
      )
      |> Repo.one()

    case exam do
      nil ->
        json(conn, %{success: false, data: %{}})

      e ->
        data =
          e
          |> Map.put(:question, length(e.question))

        if data.publish do
          json(conn, %{success: true, data: data})
        else
          if id_user in data.list_user_do do
            json(conn, %{success: true, data: data})
          else
            json(conn, %{success: false, data: %{}, status: "You cant do this exam"})
          end
        end
    end
  end

  def get_exam(id_exam, type_get, id_user) do
    exam_query =
      from(e in Exam,
        where: e.id == ^id_exam,
        select: %{
          id: e.id,
          class: e.class,
          subject: e.subject,
          time: e.time,
          start: e.start,
          question: e.question,
          list_user_do: e.list_user_do,
          number_students: e.number_students,
          publish: e.publish,
          type_exam: e.type_exam
        }
        # preload: [:question]
      )
      |> Repo.one()

    case exam_query do
      nil ->
        %{data: %{}, status: "ID exam is incorrect", error: true, success: false}

      _ ->
        data_exam =
          Map.take(exam_query, [
            :id,
            :class,
            :subject,
            :time,
            :start,
            :question,
            :list_user_do,
            :number_students,
            :publish
          ])

        question_data =
          question_query =
          from(q in Question,
            where: q.id in ^data_exam.question,
            select: %{
              parent_question: q.parent_question,
              id: q.id,
              question: q.question,
              url_media: q.url_media,
              level: q.level,
              type: q.type,
              as: q.as
            }
          )

        question_query =
          if type_get do
            from(q in question_query, select_merge: %{correct_ans: q.correct_ans})
          else
            question_query
          end

        question_data = Repo.all(question_query)

        data =
          Map.merge(data_exam, %{
            question: question_data
          })

        case data_exam.publish do
          true ->
            %{data: data, success: true}

          false ->
            if id_user in data_exam.list_user_do do
              %{data: data, success: true}
            else
              %{data: %{}, status: "You cant do the exam", success: false}
            end
        end
    end
  end

  def get_list(conn, params) do
    t = get_exam_by_subject("T")
    l = get_exam_by_subject("L")
    h = get_exam_by_subject("H")

    json(conn, %{
      data: %{
        T: t,
        L: l,
        H: h
      },
      success: true
    })
  end

  def get_exam_by_subject(s) do
    exam =
      from(e in Exam,
        where: e.subject == ^s and e.type_exam == "exam",
        limit: 5,
        order_by: [desc: :id],
        select: %{
          subject: e.subject,
          publish: e.publish,
          detail: e.detail,
          id: e.id,
          at: e.inserted_at,
          start: e.start
        }
      )
      |> Repo.all()
  end

  def my_exam(conn, p) do
    subject = p["subject"] || "all"
    afterE = p["after"] || nil
    id_user = conn.assigns.user.user_id

    subject =
      if subject == "all" do
        ["T", "L", "H"]
      else
        ["subject"]
      end

    exam =
      case afterE do
        nil ->
          from(e in Exam,
            where:
              e.subject in ^subject and e.type_exam == "custom_exam" and e.user_id == ^id_user,
            limit: 5,
            order_by: [desc: :id],
            select: e
          )

        _ ->
          from(e in Exam,
            where:
              e.subject in ^subject and e.type_exam == "custom_exam" and e.user_id == ^id_user,
            group_by: e.id,
            having: e.id < ^afterE,
            limit: 5,
            order_by: [desc: :id],
            select: e
          )
      end
      |> Repo.all()
      |> Enum.map(fn d ->
        {:ok, f} =
          d
          |> Map.drop([:__meta__])
          |> Poison.encode()

        f
        |> Poison.decode!()
      end)

    json(conn, %{data: exam, success: true})
  end

  def get_info(conn, p) do
    id_user = conn.assigns.user.user_id
    id_e = p["id"] || 0

    e =
      from(e in Exam,
        where: e.id == ^id_e and e.user_id == ^id_user,
        select: [
          :id,
          :class,
          :subject,
          :time,
          :start,
          :publish,
          :question,
          :list_user_do,
          :detail,
          :user_id,
          :inserted_at,
          :setting
        ]
      )
      |> Repo.one()

    IO.inspect(e)

    case e do
      nil ->
        json(conn, %{data: %{}, message: "Not found exam", success: false})

      _ ->
        q =
          from(q in Question,
            where: q.id in ^(e.question || []),
            select: %{
              id: q.id,
              as: q.as,
              correct_ans: q.correct_ans,
              question: q.question,
              url_media: q.url_media,
              status: q.status
            }
          )
          |> Repo.all()

        u =
          from(u in User,
            where: u.id in ^(e.list_user_do || []),
            select: %{id: u.id, email: u.email, name: u.name}
          )
          |> Repo.all()

        {:ok, ex} =
          Map.merge(e, %{"question_data" => q, "user_data" => u})
          |> Map.drop([:__meta__])
          |> Poison.encode()

        e =
          ex
          |> Poison.decode!()

        json(conn, %{data: e, success: true})
    end
  end
end
