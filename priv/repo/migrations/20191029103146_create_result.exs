defmodule Exam.Repo.Migrations.CreateResult do
  use Ecto.Migration

  def change do
    create table(:results) do
      add :user_id, references(:users)
      add :result, :map
      add :exam_id, references(:exams)

      timestamps()
    end
  end
end
