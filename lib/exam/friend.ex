defmodule Exam.Friend do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  alias Exam.Question
  use ExamWeb, :model

  schema "friends" do
    field :per1, :integer
    field :per2, :integer
    field :nick_name, {:array, :map}
    field :status, :string
    field :conv, :string
    timestamps()
  end

  @doc false
  def changeset(e, attrs) do
    e
    |> cast(attrs, [
      :per1,
      :per2,
      :nick_name,
      :status,
      :conv
    ])
    |> validate_required([
      :per1,
      :per2,
      :nick_name,
      :status,
      :conv
    ])
  end
end
