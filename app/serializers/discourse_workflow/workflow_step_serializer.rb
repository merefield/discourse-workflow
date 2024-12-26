module DiscourseWorkflow
  class WorkflowStepSerializer < ApplicationSerializer

    attributes :id,
              :category_id,
              :workflow_step_id,
              :slug,
              :name,
              :description,
              :step_type

    has_many :workflow_step_option, serializer: WorkflowStepOptionSerializer, embed: :object

  end
end
