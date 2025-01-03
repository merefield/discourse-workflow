module DiscourseWorkflow
  class WorkflowActionController < ApplicationController
    def act
      workflow_state = WorkflowState.find_by(topic_id: params[:topic_id])
      topic = Topic.find(params[:topic_id])
      if workflow_state && topic
        workflow_state.workflow_step.workflow_step_option.each do |workflow_step_option|
          if workflow_step_option.workflow_option.slug == params[:option]
            target_workflow_step = WorkflowStep.find_by(id: workflow_step_option.target_step_id)
            if target_workflow_step
              topic.category_id = target_workflow_step.category_id
              topic.save!
              workflow_state.update!(workflow_step_id: workflow_step_option.target_step_id)
            end
          end
        end
      end 
      render json: success_json
    end
  end
end