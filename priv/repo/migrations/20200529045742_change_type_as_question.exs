defmodule Exam.Repo.Migrations.ChangeTypeAsQuestion do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE questions ALTER COLUMN \"as\" TYPE text[] USING (\"as\"::text[])"
  end
end
