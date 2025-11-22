# frozen_string_literal: true

module DiscourseWorkflow
  class Transition
    def transition(user_id, topic, option)
      success = false

      workflow_state =
        DiscourseWorkflow::WorkflowState
          .includes(:workflow, workflow_step: { workflow_step_options: :workflow_option })
          .find_by(topic_id: topic.id)

      return false unless workflow_state && topic

      current_step = workflow_state.workflow_step
      return false unless current_step

      starting_step_id       = current_step.id
      starting_step_name     = current_step.name
      starting_position      = current_step.position
      starting_category_id   = topic.category_id
      starting_category_name = topic.category&.name

      WorkflowState.transaction do
        current_step.workflow_step_options.each do |workflow_step_option|
          next unless workflow_step_option.workflow_option&.slug == option

          step_option_id   = workflow_step_option.id
          step_option_name = workflow_step_option.workflow_option.name
          step_option_slug = workflow_step_option.workflow_option.slug

          target_step =
            DiscourseWorkflow::WorkflowStep.find_by(id: workflow_step_option.target_step_id)
          next unless target_step

          # move topic + workflow state
          topic.update!(category_id: target_step.category_id)
          workflow_state.update!(workflow_step_id: target_step.id)

          if user_id.present?
            user     = User.find(user_id)
            username = user.username
          else
            # stick with your -1/system idiom, but avoid double find
            user     = nil
            user_id  = -1
            username = "system"
          end

          WorkflowAuditLog.create!(
            user_id:                user_id,
            username:               username,
            topic_id:               topic.id,
            topic_title:            topic.title,
            workflow_id:            workflow_state.workflow_id,
            workflow_name:          workflow_state.workflow.name,
            starting_step_id:       starting_step_id,
            starting_step_name:     starting_step_name,
            ending_step_id:         workflow_state.workflow_step_id,
            ending_step_name:       workflow_state.workflow_step.name,
            starting_category_id:   starting_category_id,
            starting_category_name: starting_category_name,
            ending_category_id:     topic.category_id,
            ending_category_name:   topic.category&.name,
            starting_position:      starting_position,
            ending_position:        workflow_state.workflow_step.position,
            step_option_id:         step_option_id,
            step_option_name:       step_option_name,
            step_option_slug:       step_option_slug
          )

          Post.create!(
            user_id:    user_id,
            topic_id:   topic.id,
            raw:        I18n.t(
                          "discourse_workflow.topic_transition_action_description",
                          workflow_step_name: workflow_state.workflow_step.name,
                          username:           username,
                          step_option_name:   step_option_name
                        ),
            post_type:  Post.types[:small_action],
            action_code: "workflow_transition"
          )

          success = true
          # no need to keep iterating once we matched the option
          break
        end
      end

      if success && topic.category_id != starting_category_id
        ::Jobs::WorkflowTopicArrivalNotifier.perform_async(
          { topic_id: topic.id }.as_json
        )
      end

      success
    end
  end
end
