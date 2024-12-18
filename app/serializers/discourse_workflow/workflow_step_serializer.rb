class WorkflowStepSerializer < ApplicationSerializer

  attributes :id,
             :workflow_step_id,
             :slug,
             :name,
             :description,
             :step_type

  has_many :workflow_step_options, serializer: WorkflowStepOptionSerializer, embed: :object

end
