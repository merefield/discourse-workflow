# frozen_string_literal: true

class ::Jobs::WorkflowDataExplorerQueriesCompleteness < ::Jobs::Scheduled
  sidekiq_options retry: false

  every 24.hours

  def execute(args)
    if !ActiveRecord::Base.connection.table_exists?(:data_explorer_queries)
      Rails.logger.warn "Skipping WorkflowDataExplorerQueriesCompleteness: doesn't look like Data Explorer plugin is properly installed"
      return
    end

    if !::DiscourseDataExplorer::Query.exists?(name: "Workflow Stats (default)")
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

    if !::DiscourseDataExplorer::Query.exists?(name: "Workflow Audit Log (default)")
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
  end
end
