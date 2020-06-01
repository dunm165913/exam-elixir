defmodule Exam.Repo.Migrations.AddColoumnTitleNews do
  use Ecto.Migration

  def change do
 alter table("news") do
    add :title, :text
  end
  end
end
