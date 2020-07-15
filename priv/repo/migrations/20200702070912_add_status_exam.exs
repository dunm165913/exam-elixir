defmodule Exam.Repo.Migrations.AddStatusExam do
  use Ecto.Migration

  def change do
    alter table(:exams) do
      add :status, :string, default: "avai"
    end
  end
end
