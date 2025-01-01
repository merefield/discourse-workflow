module DiscourseWorkflow
  class WorkflowStepOptionSerializer < ApplicationSerializer

    attributes :id,
              :workflow_option_id,
              :position,
              :target_step_id

    def name
      DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.name
    end

    def slug
      DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.slug
    end
  end
end