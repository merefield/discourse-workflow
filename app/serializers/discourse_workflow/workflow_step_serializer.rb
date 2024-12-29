module DiscourseWorkflow
  class WorkflowStepSerializer < ApplicationSerializer

    attributes :id,
              :workflow_id,
              :category_id,
              :workflow_step_id,
              :slug,
              :name,
              :description,
              :step_type

    has_many :workflow_step_option, serializer: WorkflowStepOptionSerializer, embed: :object
    has_one :category, serializer: CategorySerializer, embed: :object

    def category
      Category.find_by(id: object.category_id) if object.category_id.present?  
    end
  end
end
