module DiscourseWorkflow
  class Transition

    def transition(user_id, topic, option, comment)
      success = false
      workflow_state = WorkflowState.find_by(topic_id: topic.id)
      if workflow_state && topic
        starting_step_id = workflow_state.workflow_step_id
        starting_step_name = workflow_state.workflow_step.name
        starting_position = workflow_state.workflow_step.position
        starting_category_id = topic.category_id
        starting_category_name = Category.find(starting_category_id).name
        WorkflowState.transaction do
          workflow_state.workflow_step.workflow_step_option.each do |workflow_step_option|
            if workflow_step_option.workflow_option.slug == option
              step_option_id = workflow_step_option.id
              step_option_name = workflow_step_option.workflow_option.name
              step_option_slug = workflow_step_option.workflow_option.slug

              target_workflow_step = WorkflowStep.find_by(  id: workflow_step_option.target_step_id)
              if target_workflow_step
                topic.category_id = target_workflow_step.category_id
                topic.save!
                workflow_state.update!(workflow_step_id: workflow_step_option.target_step_id)
                user = User.find(user_id)
                username = User.find(user_id).username
                WorkflowAuditLog.create!(
                  user_id: user.id,
                  username: user.username,
                  topic_id: topic.id,
                  topic_title: topic.title,
                  workflow_id: workflow_state.workflow_id,
                  workflow_name: workflow_state.workflow.name,
                  starting_step_id: starting_step_id,
                  starting_step_name: starting_step_name,
                  ending_step_id: workflow_state.workflow_step_id,
                  ending_step_name: workflow_state.workflow_step.name,
                  starting_category_id: starting_category_id,
                  starting_category_name: starting_category_name,
                  ending_category_id: topic.category_id,
                  ending_category_name: Category.find(topic.category_id).name,
                  starting_position: starting_position,
                  ending_position: workflow_state.workflow_step.position,
                  step_option_id: step_option_id,
                  step_option_name: step_option_name,
                  step_option_slug: step_option_slug,
                  comment: comment
                )
                success = true
              end
            end
          end
        end
      end 
      success
    end

  end
end
