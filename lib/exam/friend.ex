defmodule Exam.Friend do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  alias Exam.Question
  use ExamWeb, :model

  schema "friends" do
    field :per1, :integer
    field :per2, :integer
    timestamps()
  end

  @doc false
  def changeset(e, attrs) do
    e
    |> cast(attrs, [
      :per1,
      :per2,
    ])
    |> validate_required([
      :per1,
      :per2,
    ])
  end
end
