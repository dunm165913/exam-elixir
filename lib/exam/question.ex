defmodule Exam.Question do
#   use Ecto.Schema
#   import Ecto.Changeset
  alias Exam.User
  use ExamWeb, :model

  schema "questions" do
    field :as, {:array, :string}
    field :correct_ans, :string
    field :question, :string
    field :parent_question, :string, default: "1"
    field :type, :string, default: "XO"
    field :subject, :string
    field :url_media, :string
    field :level, :string, default: "1"
    field :class, :string, default: "12"
    field :detail, :string
    # field :user_id, :integer
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:as, :correct_ans, :question, :creator_id])
    |> validate_required([:as, :correct_ans, :question, :creator_id])
  end
end
