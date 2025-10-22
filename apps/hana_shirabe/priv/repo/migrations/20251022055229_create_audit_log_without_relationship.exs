defmodule HanaShirabe.Repo.Migrations.CreateAuditLogWithoutRelationship do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :scope, :string
      add :verb, :string
      add :ip_addr, :string
      add :user_agent, :string
      add :context, :map
      # add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(updated_at: false)
    end

    # create index(:audit_logs, [:user_id])
  end
end
