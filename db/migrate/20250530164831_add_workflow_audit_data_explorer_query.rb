# frozen_string_literal: true
class AddWorkflowAuditDataExplorerQuery < ActiveRecord::Migration[7.2]
  def up
    unless table_exists?(:data_explorer_queries)
      warn "Skipping AddWorkflowStatsDataExplorerQuery: data_explorer_queries table does not exist"
      # abort the migration so it does NOT get marked as run
      raise ActiveRecord::MigrationError, "Table data_explorer_queries does not exist"
    end

    query_sql = <<~SQL
      -- [params]
      -- int :workflow_id = 1
      -- int :num_of_days_history = 14

      SELECT user_id,
          topic_id,
          workflow_name,
          starting_step_name,
          step_option_name
      FROM
          workflow_audit_logs
      WHERE created_at >= NOW() - (:num_of_days_history * INTERVAL '1 day')
      AND workflow_id = :workflow_id
    SQL

    DB.exec <<~SQL, now: Time.zone.now, query_sql: query_sql
      INSERT INTO data_explorer_queries(name, description, sql, created_at, updated_at)
      VALUES
      ('Workflow Audit Log (default)',
      'Audit log for workflow actions',
      :query_sql,
      :now,
      :now)
    SQL
  end

  def down
    return unless table_exists?(:data_explorer_queries)

    DB.exec <<~SQL
      DELETE FROM data_explorer_queries
      WHERE name = 'Workflow Audit Log (default)';
    SQL
  end
end
