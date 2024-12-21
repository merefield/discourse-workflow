# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowSerializer < ApplicationSerializer
    root "workflow"

    attributes :id,
              :name,
              :description,
              :enabled,
              :workflow_steps_count,
              :starting_category_id,
              :final_category_id

    has_many :workflow_steps, serializer: WorkflowStepSerializer, embed: :object

    def workflow_steps_count
      object.workflow_steps.count
    end

    def starting_category_id
      object.workflow_steps.first&.category_id
    end

    def final_category_id
      object.workflow_steps.last&.category_id
    end

    # def workflow_steps
    #   object.workflow_steps
    # end

    # def name
    #   object.class_instance.name
    # end

    # def description
    #   object.class_instance.description
    # end
  end
end