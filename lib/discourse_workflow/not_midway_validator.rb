# frozen_string_literal: true

module DiscourseWorkflow
  class NotMidwayValidator < ActiveModel::Validator
    def validate(record)
      return unless SiteSetting.workflow_enabled?
      return if record.private_message?

      active_steps =
        WorkflowStep
          .joins(:workflow)
          .where(category_id: record.category_id, workflows: { enabled: true })

      return if !active_steps.exists?
      return if active_steps.where(position: 1).exists?
      # return if record.user.staff?

      workflow_in_progress =
        active_steps.where("workflow_steps.position > 1").exists?
      if workflow_in_progress
        record.errors.add(:base, message: I18n.t("discourse_workflow.errors.no_midway_error"))
      end
    end
  end
end
