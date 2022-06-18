defmodule Exam.Repo.Migrations.ChangeTypeNew do
  use Ecto.Migration

  def change do
alter table(:news) do
  modify :data, :text
    modify :title, :text
end
  end
end
