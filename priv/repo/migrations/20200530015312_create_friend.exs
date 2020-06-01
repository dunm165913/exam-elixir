defmodule Exam.Repo.Migrations.CreateFriend do
  use Ecto.Migration

  def change do
    create table(:friends) do
      add :per1, :integer
      add :per2, :integer
    end
  end
end
