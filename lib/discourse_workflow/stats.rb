module DiscourseWorkflow
  class Stats

    def calculate_daily_stats
      return unless SiteSetting.workflow_enabled

      current_date = Date.current

      ::DiscourseWorkflow::WorkflowStat.where(cob_date: current_date).destroy_all

      Workflow.all.each do |workflow|
        workflow.workflow_state.each do |state|
          stat = ::DiscourseWorkflow::WorkflowStat.find_or_initialize_by(
            cob_date:          current_date,
            workflow_id:       workflow.id,
            workflow_step_id:  state.workflow_step_id
          )
          stat.count ||= 0
          stat.count += 1
          stat.save!
        end
        ::Rails.logger.info("Workflow Daily Stats recorded for: #{workflow.name}")
      end
    end
  end
end
