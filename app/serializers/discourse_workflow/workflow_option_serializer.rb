module DiscourseWorkflow
  class WorkflowOptionSerializer < ApplicationSerializer

    attributes :id,
              :name,
              :slug

    # def name
    #   DiscourseWorkflow::WorkflowOption.find_by(id: object.workflow_option_id)&.name
    # end

    # def slug
    #   DiscourseWorkflow::WorkflowOption.find_by(id: object.workflow_option_id)&.slug
    # end
  end
end