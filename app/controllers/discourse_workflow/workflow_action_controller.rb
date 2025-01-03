module DiscourseWorkflow
  class WorkflowActionController < ApplicationController

    def act
      success = false
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_create_topic_on_category!(topic.category_id)
      workflow_state = WorkflowState.find_by(topic_id: params[:topic_id])

      if workflow_state && topic
        workflow_state.workflow_step.workflow_step_option.each do |workflow_step_option|
          if workflow_step_option.workflow_option.slug == params[:option]
            target_workflow_step = WorkflowStep.find_by(id: workflow_step_option.target_step_id)
            if target_workflow_step
              topic.category_id = target_workflow_step.category_id
              topic.save!
              workflow_state.update!(workflow_step_id: workflow_step_option.target_step_id)
              success = true
            end
          end
        end
      end 
      if success
        render json: success_json
      else
        render json: failed_json
      end
    end
  end
end