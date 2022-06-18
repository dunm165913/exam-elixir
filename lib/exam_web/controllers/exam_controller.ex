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
           :update_exam,
           :my_exam_done
         ]
  )

  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  @spec index(Plug.Conn.t(), nil | keyword | map) :: Plug.Conn.t()
  def index(conn, parmas) do
    id_exam = parmas["id"]
    create_default = parmas["creat_default"] || "true"

    id_user = conn.assigns.user.user_id

    case id_exam do
      nil ->
        json(conn, %{data: %{}, status: "No id exam", success: false})

      _ ->
        data = get_exam(id_exam, false, id_user)
        IO.inspect(data)

        if data.success do
          now = DateTime.utc_now()

          if now < data.data.start do
            json(conn, %{data: %{}, success: false, message: "Chưa tới giờ làm bài"})
          else
            if create_default == "true" do
              re = ExamWeb.ResultController.create_default(id_exam, id_user, "exam")

              if re.success do
                data =
                  data
                  |> Map.put("result", re.data)

                json(conn, %{data: data, success: true})
              else
                json(conn, %{data: %{}, message: "Lỗi khi tạo default", success: false})
              end
            else
              json(conn, %{data: data, success: true})
            end
          end
        else
          json(conn, %{data: %{}, message: "không thể làm bài thi", success: false})
        end
    end
  end

  def options(conn, params) do
    json(conn, %{})
  end

  def create(conn, params) do
    data = params["data"] || %{}

    # data =
    #   if Map.has_key?(data, "start") do
    #     data
    #   else
    #     Map.put(data, "start", DateTime.utc_now() |> DateTime.add(60 * 60 * 24 * 7, :second))
    #   end

    IO.inspect(params)

    question =
      data["question"]
      |> Enum.map(fn qid ->
        IO.inspect(qid)
        encode_str(qid)
      end)

    IO.inspect(">>>>>>>>>>>")
    IO.inspect(question)

    is_admin = data["is_admin"]

    id_user = conn.assigns.user.user_id

    # user = Repo.get(User, id_user)
    # IO.inspect(user.role)
    # json(conn, %{})
    result =
      if is_admin do
        check = ExamWeb.UserController.check_is_admin(params["access_token"])

        if check.success do
          Exam.changeset(
            %Exam{},
            Map.merge(data, %{
              "user_id" => id_user,
              "publish" => true,
              "type_exam" => "exam",
              "question" => question
            })
          )
        else
          json(conn, %{success: false, message: "not admin"})
        end
      else
        Exam.changeset(
          %Exam{},
          Map.merge(data, %{
            "user_id" => id_user,
            "type_exam" => "custom_exam",
            "question" => question
          })
        )
      end
      |> Repo.insert()

    IO.inspect(result)

    # roll == admiin => exam must be published and type's exam is exam
    # if roll != admin => type's exam is custom exam and

    case result do
      {:ok, d} ->
        {:ok, j} =
          d
          |> Map.drop([:__meta__])
          |> Poison.encode()

        j =
          j
          |> Poison.decode!()

        # only send exam is custom_exam
        if !is_admin do
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
                   "data" => %{"message" => "Bạn được mời làm bài thi"},
                   "actions" => %{"url" => "/exam/#{j["id"]}/intro"},
                   "setting" => %{}
                 }}
              )
            end)

          send_noti(j["list_user_do"] || [], j)
        end

        json(conn, %{data: j, success: true})

      # send Notification to User who can do

      {:error, c} ->
        IO.inspect(c)
        json(conn, %{data: %{}, success: false, message: "Kiểm tra lại thông tin"})
    end
  end

  @spec send_noti(any, any) :: [any]
  def send_noti(listU, exam) do
    listU
    |> Enum.map(fn x ->
      GenServer.cast(
        ExamWeb.Notification,
        {:create_notification_exam,
         %{
           "from" => %{"source" => "Đề thi #{exam["id"]}", "exam" => exam["id"]},
           "to" => x,
           "media" => %{},
           "data" => %{"message" => "Bạn được mời tham gia bài thi."},
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
            if d.correct_ans == client_ans["#{d["id"]}"] do
              acc ++
                [
                  %{
                    id: d["id"],
                    result: true,
                    your_ans: client_ans["#{d["id"]}"]
                  }
                ]
            else
              acc ++
                [
                  %{
                    id: d["id"],
                    result: false,
                    your_ans: client_ans["#{d["id"]}"]
                  }
                ]
            end
          end)

        # # IO.inspect(result)
        # save result

        current_result = Repo.get!(Result, id_ref)
        setting = current_result.setting

        has_protect_mark =
          if data.data.type_exam == "custom_exam" do
            true
          else
            if Map.has_key?(setting, "protect_mark") do
              setting["protect_mark"]
            else
              false
            end
          end

        IO.inspect(has_protect_mark)

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

    question =
      p["data"]["question"]
      |> Enum.map(fn qid ->
        encode_str("#{qid}")
      end)

    IO.inspect(question)

    now = DateTime.utc_now()
    add1day = now |> DateTime.add(60 * 60 * 24, :second)

    e =
      from(e in Exam,
        where: e.id == ^id_e and e.user_id == ^id_user and e.start > ^add1day
      )
      |> Repo.one()

    IO.inspect(e)

    case e do
      nil ->
        json(conn, %{
          data: %{},
          message: "Không tìm thấy bài thi hoặc bài thi đã diễn ra",
          success: false
        })

      _ ->
        result =
          Exam.changeset(
            e,
            Map.merge(p["data"], %{"type_exam" => e.type_exam, "question" => question})
          )
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
        message: "Không đủe quyền đề thực hiện hành động này"
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

  @spec get_intro(Plug.Conn.t(), nil | keyword | map) :: Plug.Conn.t()
  def get_intro(conn, parmas) do
    id_exam = parmas["id_exam"]

    id_user = conn.assigns.user.user_id

    exam =
      from(e in Exam,
        where: e.id == ^id_exam and e.status == "avai",
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
          status: e.status
        }
      )
      |> Repo.one()

    case exam do
      nil ->
        json(conn, %{success: false, data: %{}, message: "Đề thi không sẵn có"})

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
            json(conn, %{success: false, data: %{}, message: "Bạn không thể làm bài thi này"})
          end
        end
    end
  end

  def get_exam(id_exam, type_get, id_user) do
    exam_query =
      from(e in Exam,
        where: e.id == ^id_exam and e.status == "avai",
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
        %{
          data: %{},
          status: "ID exam is incorrect or exam is unavailabel",
          error: true,
          success: false
        }

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
            :publish,
            :type_exam
          ])

        id_q =
          data_exam.question
          |> Enum.map(fn t ->
            decode(t)
          end)

        question_data =
          question_query =
          from(q in Question,
            where: q.id in ^id_q,
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
        q_d = g(0, question_data, data_exam.question)

        data =
          Map.merge(data_exam, %{
            question: q_d
          })

        case data_exam.type_exam do
          "exam" ->
            %{data: data, success: true}

          "custom_exam" ->
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
    id = p["id"] || nil

    subject =
      if subject == "all" do
        ["T", "L", "H"]
      else
        ["subject"]
      end

    exam =
      case id do
        nil ->
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

        _ ->
          from(e in Exam,
            where: e.id == ^id and e.user_id == ^id_user,
            group_by: e.id,
            limit: 1,
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
          :setting,
          :status
        ]
      )
      |> Repo.one()

    IO.inspect(e)

    case e do
      nil ->
        json(conn, %{data: %{}, message: "Không tìm thấy đề thi", success: false})

      _ ->
        q_d =
          e.question
          |> Enum.map(fn v ->
            if String.match?("#{v}", ~r/exam/) do
              decode("#{v}")
            else
              v
            end
          end)

        q =
          from(q in Question,
            where: q.id in ^q_d,
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

  def my_exam_done(conn, p) do
    id_user = conn.assigns.user.user_id
    data = ExamWeb.ResultController.my_exam_done(id_user)
    json(conn, data)
  end

  def encode_n(n) do
    case n do
      "0" -> "w"
      "1" -> "a"
      "2" -> "b"
      "3" -> "c"
      "4" -> "d"
      "5" -> "e"
      "6" -> "f"
      "7" -> "g"
      "8" -> "h"
      "9" -> "i"
      "j" -> "j"
      "w" -> "0"
      "a" -> "1"
      "b" -> "2"
      "c" -> "3"
      "d" -> "4"
      "e" -> "5"
      "f" -> "6"
      "g" -> "7"
      "h" -> "8"
      "i" -> "9"
      "j" -> "j"
    end
  end

  def encode_str(str) do
    r =
      String.split(str, "")
      |> Enum.filter(fn x -> x != "" end)

    r = ["j"] ++ r

    data =
      add(r)
      |> Enum.map(fn s -> encode_n(s) end)
      |> Enum.join("")

    "exam_#{data}"
  end

  def add(str) do
    if Enum.count(str) == 10 do
      str
    else
      add(["#{Enum.random(0..9)}"] ++ str)
    end
  end

  def decode(str) do
    r =
      String.split(str, "j")
      |> Enum.at(1)
      |> String.split("")
      |> Enum.filter(fn x -> x != "" end)
      |> Enum.map(fn h -> encode_n(h) end)
      |> Enum.join("")

    r
  end

  @spec g(integer, any, any) :: [map, ...]
  # merger id to question
  def g(i, s1, s2) do
    if i == Enum.count(s1) - 1 do
      [Map.merge(Enum.at(s1, i), %{"id" => Enum.at(s2, i)})]
    else
      [Map.merge(Enum.at(s1, i), %{"id" => Enum.at(s2, i)})] ++ g(i + 1, s1, s2)
    end
  end

  def get_list_by_admin(conn, p) do
    sub =
      if p["subject"] do
        [p["subject"]]
      else
        ["T", "L", "H"]
      end

    u = ExamWeb.UserController.check_is_admin(p["access_token"])

    if u.success do
      e =
        from(e in Exam,
          where: e.type_exam == "exam" and e.subject in ^sub,
          limit: 30,
          select: %{
            user_id: e.user_id,
            class: e.class,
            subject: e.subject,
            numq: e.question,
            time: e.time,
            insert: e.inserted_at,
            id: e.id
          }
        )
        |> Repo.all()

      json(conn, %{data: e, success: true})
    else
      json(conn, %{data: [], success: false, message: "Not admin"})
    end
  end
end
