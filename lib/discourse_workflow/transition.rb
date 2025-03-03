# frozen_string_literal: true

module DiscourseWorkflow
  class Transition

    def transition(user_id, topic, option)
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

              target_workflow_step = WorkflowStep.find_by(id: workflow_step_option.target_step_id)
              if target_workflow_step
                topic.category_id = target_workflow_step.category_id
                topic.save!
                workflow_state.update!(workflow_step_id: workflow_step_option.target_step_id)
                if user_id.present?
                  user = User.find(user_id)
                  username = User.find(user_id).username
                else
                  user_id = -1
                  username = 'system'
                end
                WorkflowAuditLog.create!(
                  user_id: user_id,
                  username: username,
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
                  step_option_slug: step_option_slug
                )

                Post.create!(
                  user_id: user_id,
                  topic_id: topic.id,
                  raw: I18n.t('discourse_workflow.topic_transition_action_description',
                    workflow_step_name: workflow_state.workflow_step.name,
                    username: username,
                    step_option_name: step_option_name
                  ),
                  post_type: Post.types[:small_action],
                  action_code: 'workflow_transition'
                )

                success = true
              end

            end
          end
        end
        if topic.category_id != starting_category_id
          opts = {
            topic_id: topic.id
          }
          job_class = ::Jobs::WorkflowTopicArrivalNotifier
          job_class.perform_async(opts.as_json)
        end
      end
      success
    end

  end
end
