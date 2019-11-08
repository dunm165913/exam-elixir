defmodule Exam.Repo.Migrations.CreateExam do
  use Ecto.Migration

  def change do
    create table(:exams) do
      add :subject, :string
      add :class, :string
      add :time, :utc_datetime
      add :start, :utc_datetime
      add :number_students, :integer
      add :publish, :boolean
      add :question, {:array, :map}
      add :list_user_do, {:array, :map}
      add :detail, :string
      add :user_id, references(:users)

      timestamps()
    end
  end
end
