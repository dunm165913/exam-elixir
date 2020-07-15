defmodule Exam.User do
  # use Ecto.Schema
  # import Ecto.Changeset
  alias Exam.Question
  alias Exam.Result
  alias Exam.Media

  use ExamWeb, :model

  schema "users" do
    field :codeVerfity, :integer
    field :email, :string
    field :name, :string
    field :password, :string
    field :role, :string, default: "student"
    field :status, :string, default: "active"
    has_many :questions, Question
    has_many :results, Result
    has_many :media, Media

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role, :codeVerfity, :status])
    |> validate_required([:email, :password])
  end
end
