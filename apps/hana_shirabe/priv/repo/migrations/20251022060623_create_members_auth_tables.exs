defmodule HanaShirabe.Repo.Migrations.CreateMembersAuthTables do
  use Ecto.Migration

  def change do
    create table(:members) do
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string
      add :confirmed_at, :naive_datetime

      timestamps()
    end

    create unique_index(:members, [:email])

    create table(:members_tokens) do
      add :member_id, references(:members, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :naive_datetime

      timestamps(updated_at: false)
    end

    create index(:members_tokens, [:member_id])
    create unique_index(:members_tokens, [:context, :token])

    create table(:audit_logs) do
      add :scope, :string
      add :verb, :string
      add :ip_addr, :string
      add :user_agent, :string
      add :context, :map
      add :member_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:member_id])
  end
end
