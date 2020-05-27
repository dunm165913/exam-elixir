defmodule Exam.Repo.Migrations.CreateReviewQuestion do
  use Ecto.Migration

  def change do
    create table("review_question") do
      add :id_ref, :string
      add :data, :map
     add :user_id, references(:users)
      timestamps()
    end
  end
end
