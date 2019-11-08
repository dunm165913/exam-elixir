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
    plug :accepts, ["json"]
  end

  scope "/", ExamWeb do
    pipe_through :api

    get "/", PageController, :index
    scope "/api" do
      scope "/adsfb" do
        get "/",        AdsfbController, :index
        post "/",       AdsfbController, :handle
      end
      scope "/slack" do
        post   "/test",      SlackController, :index
        post   "/",          SlackController, :handel
      end
      scope "/user" do
        get     "/",            UserController,    :index
        post    "/signup",            UserController,    :create
        post    "/login",        UserController,    :login
        post    "/login_email",        UserController,    :login_email
      end
      scope "/question" do
        get     "/",            QuestionController, :index
        post    "/",            QuestionController, :create
      end
      scope "/exam" do
        get     "/",            ExamController, :index
        post    "/result",      ExamController, :check_result 
        post    "/change_user", ExamController, :change_user 
        post    "/change_question", ExamController, :change_question
      end
      scope "/result" do
        get     "/",             ResultController, :get_result
      end
    end

  end

  # Other scopes may use custom stacks.
  # scope "/api", ExamWeb 
  #   pipe_through :api
  # end
end
