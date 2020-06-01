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
    field :subject, :string, default: ""
    field :url_media, :string, default: ""
    field :level, :string, default: "1"
    field :class, :string, default: "12"
    field :detail, :string, default: ""
    field :status, :string, default: "review"
    field :mark, :float, default: 0.0
    # field :user_id, :integer
    belongs_to :user, User

    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(questions, attrs) do
    questions
    |> cast(attrs, [
      :as,
      :correct_ans,
      :question,
      :parent_question,
      :type,
      :subject,
      # :url_media,
      :level,
      :class,
      :user_id,
      # :detail,
      # :status,
      # :mark
    ])
    |> validate_required([
      :as,
      :correct_ans,
      :question,
      :parent_question,
      :type,
      :subject,
      # :url_media,
      :level,
      :class,
      :user_id,
      # :detail,
      :status,
      # :mark
    ])
  end
end
