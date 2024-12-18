class WorkflowpOptionSerializer < ApplicationSerializer

  attributes :id,
             :workflow_option_id,
             :workflow_step_option_id,
             :target_step_id

  def name
    DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.name
  end

  def slug
    DiscourseWorkflow::WorkflowStepOption.find_by(id: object.workflow_option_id)&.slug
  end
end