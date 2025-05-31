# frozen_string_literal: true
class AddWorkflowStatsDataExplorerQuery < ActiveRecord::Migration[7.2]
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

      SELECT 
          cob_date as "COB DATE",
          w.name as "Workflow",
          wstp.name as "Step",
          wstt.count as "Count"
      FROM workflow_stats wstt
      INNER JOIN workflow_steps wstp ON wstt.workflow_step_id = wstp.id
      INNER JOIN workflows w ON wstt.workflow_id = w.id
      WHERE wstt.cob_date >= NOW() - (:num_of_days_history * INTERVAL '1 day')
        AND wstt.workflow_id = :workflow_id
    SQL

    DB.exec <<~SQL, now: Time.zone.now, query_sql: query_sql
      INSERT INTO data_explorer_queries(name, description, sql, created_at, updated_at)
      VALUES
      ('Workflow Stats (default)',
      'Daily counts for each workflow step in a workflow (useful for e.g. burndown/burnup charts)',
      :query_sql,
      :now,
      :now)
    SQL
  end

  def down
    return unless table_exists?(:data_explorer_queries)

    DB.exec <<~SQL
      DELETE FROM data_explorer_queries
      WHERE name = 'Workflow Stats (default)';
    SQL
  end
end
