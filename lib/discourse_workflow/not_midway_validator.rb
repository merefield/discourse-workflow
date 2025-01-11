# frozen_string_literal: true

module DiscourseWorkflow
  class NotMidwayValidator < ActiveModel::Validator
    def validate(record)
      return unless SiteSetting.workflow_enabled?
      return if record.private_message?
      return if !WorkflowStep.where(category_id: record.category_id).exists?
      return if WorkflowStep.where(category_id: record.category_id, position: 1).exists?
      # return if record.user.staff?

      workflow_in_progress = WorkflowStep.where(category_id: record.category_id).where("position > 1").exists?
      if workflow_in_progress
        record.errors.add(:base, message: I18n.t("discourse_workflow.errors.no_midway_error"))
      end
    end
  end
end
