module DiscourseWorkflow
  class WorkflowStepOptionSerializer < ApplicationSerializer

    attributes :id,
              :workflow_option_id,
              :workflow_step_id,
              :workflow_id,
              :position,
              :target_step_id

    has_one :workflow_option, serializer: WorkflowOptionSerializer, embed: :object, key: :workflow_option

    def workflow_id
      object.workflow_step.workflow_id
    end
    # def name
    #   DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.name
    # end

    # def slug
    #   DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.slug
    # end
  end
end