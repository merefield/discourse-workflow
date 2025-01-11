# frozen_string_literal: true
class CreateWorkflowDataExplorerQuery < ActiveRecord::Migration[7.2]
  def up
    DB.exec <<~SQL, now: Time.zone.now
      INSERT INTO data_explorer_queries(name, description, sql, created_at, updated_at)
      VALUES
      ('Worklflow Audit Log (default)',
      'Audit log for workflow actions',
      'SELECT user_id,
        topic_id,
        workflow_name,
        starting_step_name,
        step_option_name
       FROM
         workflow_audit_logs',
      :now,
      :now)
    SQL
  end

  def down
    DB.exec <<~SQL
      DELETE FROM data_explorer_queries
      WHERE name = "Worklflow Audit Log (default)";
    SQL
  end
end
