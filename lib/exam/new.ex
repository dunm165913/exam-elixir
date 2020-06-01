defmodule Exam.New do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  use ExamWeb, :model

  schema "news" do
    field :data, :string
    field :id_ref, :string
    field :setting, :map
    field :source, :string
    field :title, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :data,
      :id_ref,
      :setting,
      :source,
      :user_id,
      # :title
      # :user_info
    ])
    |> validate_required([
      :data,
      :id_ref,
      :setting,
      :source,
      :user_id,
      # :title
      # :user_info
    ])
  end
end
