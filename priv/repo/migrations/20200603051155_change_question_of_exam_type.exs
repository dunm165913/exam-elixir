defmodule Exam.Repo.Migrations.ChangeQuestionOfExamType do
  use Ecto.Migration

  def change do
execute "ALTER TABLE exams ALTER COLUMN question TYPE text[] USING (question::text[])"
  end
end
