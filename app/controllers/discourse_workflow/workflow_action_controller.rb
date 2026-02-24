# frozen_string_literal: true

module DiscourseWorkflow
  class WorkflowActionController < ApplicationController
    requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

    def act
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_create_topic_on_category!(topic.category_id)
      user = current_user
      option = params[:option]
      cooldown_key = nil
      successful_transition = false

      if user.present? && option.present? && topic.present?
        cooldown_key = "discourse-workflow-transition-#{user.id}-#{topic.id}"
        cooldown_acquired = Discourse.redis.set(cooldown_key, "1", ex: 5, nx: true)

        if !cooldown_acquired
          render json: failed_json
          return
        end

        successful_transition = Transition.new.transition(user, topic, option)
      end

      Discourse.redis.del(cooldown_key) if !successful_transition && cooldown_key.present?

      if successful_transition
        render json: success_json
      else
        render json:
                 failed_json.merge(
                   message:
                     I18n.t("discourse_workflow.errors.transition_failed_stale_state_refreshing"),
                 ),
               status: :conflict
      end
    end
  end
end
