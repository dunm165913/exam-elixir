defmodule ExamWeb.Router do
  use ExamWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    # plug :protect_from_forgery
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(CORSPlug, origin: "*")
    plug(:accepts, ["json"])
  end

  scope "/", ExamWeb do
    pipe_through(:api)

    get("/", PageController, :index)
    get("/entry_point", PageController, :get_data)
    post("/entry_point", PageController, :post_data)

    scope "/api" do
      scope "/media" do
        post("/upload", MediaController, :upload)
        options("/upload", ExamController, :option)
        post("/delete", MediaController, :delete_media)
      end

      scope "/adsfb" do
        get("/", AdsfbController, :index)
        post("/", AdsfbController, :handle)
      end

      scope "/slack" do
        post("/test", SlackController, :index)
        post("/", SlackController, :handel)
      end

      scope "/user" do
        get("/", UserController, :index)
        post("/signup", UserController, :create)
        options("/signup", UserController, :option)
        post("/login", UserController, :login)
        options("/login", UserController, :option)
        post("/login_email", UserController, :login_email)
        post("/search", UserController, :search)
        options("/search", UserController, :option)
        get("/check_admin", UserController, :check_admin)
      end

      scope "/question" do
        get("/", QuestionController, :index)
        post("/", QuestionController, :create)
        options("/", ExamController, :option)
        post("/update", QuestionController, :update_question)
        options("/update", ExamController, :option)
        get("/doquestion", QuestionController, :do_question)
        post("/checkquestion", QuestionController, :check_question)
        options("/checkquestion", ExamController, :option)
        get("/getrandom", QuestionController, :get_random_question)
        get("/question_new", QuestionController, :get_new)
        post("/question_new", QuestionController, :create_review)
        post("/delete_submit_question_new", QuestionController, :delete_submit_question_new)
        options("/delete_submit_question_new", ExamController, :option)
        options("/question_new", ExamController, :option)
        get("/my_question", QuestionController, :get_question)
        get("/get_question", QuestionController, :get_question)
      end

      scope "/exam" do
        get("/intro", ExamController, :get_intro)
        get("/get_list", ExamController, :get_list)
        get("/", ExamController, :index)
        post("/", ExamController, :create)
        options("/", ExamController, :option)
        options("/result", ExamController, :option)
        post("/result", ExamController, :check_result)
        options("/update", ExamController, :option)
        post("/update", ExamController, :update_exam)
        options("/change_question", ExamController, :option)
        get("/my_exam", ExamController, :my_exam)
        get("/get_info", ExamController, :get_info)
        get("/check_is_creator", ExamController, :check_is_creator)
        get("/statistic", ExamController, :statistic)
        get("/my_exam_done", ExamController, :my_exam_done)
      end

      scope "rate" do
        get("/exam", RateController, :get_rate_exam_total)

        scope "exam_by_user" do
          get("/", RateController, :index)
          post("/", RateController, :create)
          options("/", RateController, :option)
        end
      end

      scope "message" do
        get("/", MessageController, :get_message)
        get("/exam", MessageController, :get_message_exam)
        post("/exam", MessageController, :crxeate_message_exam)
        options("/exam", ExamController, :option)
      end

      scope "/result" do
        get("/", ResultController, :get_result)
        post("/", ResultController, :create)
        get("/get_result_exam", ResultController, :get_result_exam)
        post("/save_snapshort_exam", ResultController, :save_snapshort_exam)
        post("/start_exam", ResultController, :start_exam)
        options("/start_exam", ExamController, :option)
        options("/save_snapshort_exam", ExamController, :option)
        get("/my_exam_done", ExamController, :my_exam_done)
      end

      scope "/statistic" do
        get("/", MarkSubject, :get_mark)
        get("/subject", MarkSubject, :get_mark_subject)
      end

      scope "/news" do
        get("/", NewController, :get_list_new)
        post("/", NewController, :create)
        options("/", ExamController, :option)
        post("/update", NewController, :update_note)
        options("/update", ExamController, :option)
        get("/detail", NewController, :detail)
      end

      scope "/notification" do
        get("/", NotificationController, :index)
      end

      scope "/pancake" do
        post("/", PancakeController, :create)
        get("/", PancakeController, :create)
      end

      scope "/friend" do
        get("/get_list_friend", FriendController, :get_list_friend)
        get("/get_message", FriendController, :get_message)
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExamWeb
  #   pipe_through :api
  # end
end
