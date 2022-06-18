defmodule Exam.Repo.Migrations.AddTypeExam do
  use Ecto.Migration

  def change do
    alter table("exams") do
      # Database type
      add :type_exam, :string
    end
  end
end
