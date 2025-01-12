if defined?(DataExplorer) == "constant" &&
  DataExplorer.class == Module &&
  DataExplorer::Query.class == Class &&
  DataExplorer::Query.find_by(name: 'Worklflow Audit Log (default)').nil?

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