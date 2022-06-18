defmodule ExamWeb.Router do
  use ExamWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug CORSPlug, origin: "*"
    plug :accepts, ["json"]
  end

  scope "/", ExamWeb do
    pipe_through :api

    get "/", PageController, :index
    get "/entry_point", PageController, :get_data
    post "/entry_point", PageController, :post_data

    scope "/api" do
      scope "/media" do
        post "/upload", MediaController, :upload
        post "/delete", MediaController, :delete_media
      end

      scope "/adsfb" do
        get "/", AdsfbController, :index
        post "/", AdsfbController, :handle
      end

      scope "/slack" do
        post "/test", SlackController, :index
        post "/", SlackController, :handel
      end

      scope "/user" do
        get "/", UserController, :index
        post "/signup", UserController, :create
        options "/signup", UserController, :option
        post "/login", UserController, :login
        options "/login", UserController, :option
        post "/login_email", UserController, :login_email
      end

      scope "/question" do
        get "/", QuestionController, :index
        post "/", QuestionController, :create
        get "/doquestion", QuestionController, :do_question
        post "/checkquestion", QuestionController, :check_question
        options "/checkquestion", ExamController, :option
        get "/getrandom", QuestionController, :get_random_question
      end

      scope "/exam" do
        get "/intro", ExamController, :get_intro
        get "/", ExamController, :index
        post "/result", ExamController, :check_result
        options "/result", ExamController, :option
        post "/change_user", ExamController, :change_user
        options "/change_user", ExamController, :option
        post "/change_question", ExamController, :change_question
        options "/change_question", ExamController, :option
      end

      scope "rate" do
        get "/exam", RateController, :get_rate_exam_total

        scope "exam_by_user" do
          get "/", RateController, :index
          post "/", RateController, :create
          options "/", RateController, :option
        end
      end

      scope "message" do
        get "/", MessageController, :get_message
        get "/exam", MessageController, :get_message_exam
        post "/exam", MessageController, :create_message_exam
        options "/exam", ExamController, :option
      end

      scope "/result" do
        get "/", ResultController, :get_result
        post "/", ResultController, :create
        get "/get_result_exam", ResultController, :get_result_exam
        post "/save_snapshort_exam", ResultController, :save_snapshort_exam
        options "/save_snapshort_exam", ExamController, :option
      end

      scope "/pancake" do
        post "/", PancakeController, :create
        get "/", PancakeController, :create
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExamWeb
  #   pipe_through :api
  # end
end
