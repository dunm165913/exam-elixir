defmodule Exam.Repo.Migrations.AddReviewResultQuestion do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add(:result_review, {:array, :map})
    end

  end
end
