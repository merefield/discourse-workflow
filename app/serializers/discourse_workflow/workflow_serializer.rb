# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowSerializer < ApplicationSerializer
    root "workflow"

    attributes :id,
               :name,
               :description,
               :enabled,
               :overdue_days,
               :show_kanban_tags,
               :kanban_compatible,
               :workflow_steps_count,
               :starting_category_id,
               :final_category_id,
               :validation_warnings

    has_many :workflow_steps,
             serializer: WorkflowStepSerializer,
             embed: :object,
             key: :workflow_steps

    def workflow_steps_count
      ordered_workflow_steps.length
    end

    def starting_category_id
      ordered_workflow_steps.first&.category_id
    end

    def final_category_id
      ordered_workflow_steps.last&.category_id
    end

    def validation_warnings
      object.validation_warnings
    end

    def kanban_compatible
      object.kanban_compatible?
    end

    private

    def ordered_workflow_steps
      @ordered_workflow_steps ||= object.workflow_steps.to_a.sort_by { |step| step.position.to_i }
    end
  end
end
