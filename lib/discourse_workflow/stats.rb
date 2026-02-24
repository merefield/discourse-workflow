# frozen_string_literal: true
module DiscourseWorkflow
  class Stats
    def calculate_daily_stats
      return unless SiteSetting.workflow_enabled

      current_date = Date.current
      now = Time.zone.now
      counts_by_workflow_step =
        ::DiscourseWorkflow::WorkflowState
          .where.not(workflow_id: nil)
          .where.not(workflow_step_id: nil)
          .group(:workflow_id, :workflow_step_id)
          .count
      records =
        counts_by_workflow_step.map do |(workflow_id, workflow_step_id), count|
          {
            cob_date: current_date,
            workflow_id: workflow_id,
            workflow_step_id: workflow_step_id,
            count: count,
            created_at: now,
            updated_at: now,
          }
        end

      # This rebuild strategy assumes a single scheduler execution.
      # In standard operation this job should not run concurrently.
      ::DiscourseWorkflow::WorkflowStat.transaction do
        ::DiscourseWorkflow::WorkflowStat.where(cob_date: current_date.all_day).delete_all
        ::DiscourseWorkflow::WorkflowStat.insert_all!(records) if records.present?
      end

      ::Rails.logger.info(
        "Workflow Daily Stats recorded for #{current_date}: #{records.length} step buckets",
      )
    end
  end
end
