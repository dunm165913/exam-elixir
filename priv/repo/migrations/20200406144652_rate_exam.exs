defmodule Exam.Repo.Migrations.RateExam do
  use Ecto.Migration

  def change do
    create table(:rateExams) do
      add :star, :string
      add :content, :string
      add :user_id, references(:users)
      add :exam_id, references(:exams)
      timestamps()
    end
  end
end
