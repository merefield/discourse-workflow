# frozen_string_literal: true

module DiscourseWorkflow
  class Transition
    def transition(actor, topic, option)
      success = false

      workflow_state =
        DiscourseWorkflow::WorkflowState.includes(
          :workflow,
          { workflow: :workflow_steps },
          { workflow_step: { workflow_step_options: :workflow_option } },
        ).find_by(topic_id: topic.id)

      return false unless workflow_state && topic

      current_step = workflow_state.workflow_step
      return false unless current_step

      step_option_by_slug =
        current_step.workflow_step_options.index_by do |workflow_step_option|
          workflow_step_option.workflow_option&.slug
        end
      workflow_step_option = step_option_by_slug[option]
      return false if workflow_step_option.blank?

      target_step =
        workflow_state.workflow.workflow_steps.find do |workflow_step|
          workflow_step.id == workflow_step_option.target_step_id
        end
      return false if target_step.blank?

      user_id, username = resolve_actor(actor)

      starting_step_id = current_step.id
      starting_step_name = current_step.name
      starting_position = current_step.position
      starting_category_id = topic.category_id
      starting_category_name = topic.category&.name

      WorkflowState.transaction do
        step_option_id = workflow_step_option.id
        step_option_name = workflow_step_option.workflow_option.name
        step_option_slug = workflow_step_option.workflow_option.slug

        # move topic + workflow state
        topic.update!(category_id: target_step.category_id)
        workflow_state.update!(workflow_step_id: target_step.id)

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
          ending_step_name: target_step.name,
          starting_category_id: starting_category_id,
          starting_category_name: starting_category_name,
          ending_category_id: topic.category_id,
          ending_category_name: topic.category&.name,
          starting_position: starting_position,
          ending_position: target_step.position,
          step_option_id: step_option_id,
          step_option_name: step_option_name,
          step_option_slug: step_option_slug,
        )

        Post.create!(
          user_id: user_id,
          topic_id: topic.id,
          raw:
            I18n.t(
              "discourse_workflow.topic_transition_action_description",
              starting_step_name: starting_step_name,
              ending_step_name: target_step.name,
              username: username,
              step_option_name: step_option_name,
            ),
          post_type: Post.types[:small_action],
          action_code: "workflow_transition",
        )

        success = true
      end

      if success && topic.category_id != starting_category_id
        ::Jobs::DiscourseWorkflow::TopicArrivalNotifier.perform_async(
          { topic_id: topic.id }.as_json,
        )
      end

      success
    end

    private

    def resolve_actor(actor)
      if actor.is_a?(::User)
        [actor.id, actor.username]
      elsif actor.present?
        user_id = actor.to_i
        username = ::User.where(id: user_id).pick(:username)
        raise ActiveRecord::RecordNotFound if username.blank?
        [user_id, username]
      else
        [-1, "system"]
      end
    end
  end
end
