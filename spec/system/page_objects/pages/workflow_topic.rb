# frozen_string_literal: true

module PageObjects
  module Pages
    class WorkflowTopic < PageObjects::Pages::Base
      def visit_topic(topic, post_number: nil)
        page.visit(topic.relative_url(post_number))
        self
      end

      def has_transition_helper_text?(text)
        has_css?(".workflow-action-helper", text: text)
      end

      def has_blocked_reason?
        has_css?(".workflow-actions-blocked-reason")
      end

      def has_disabled_action_button?
        has_css?(".workflow-action-button .btn[disabled]")
      end

      def has_step_age_badge_text?(text)
        has_css?(".workflow-step-age-badge", text: text)
      end
    end
  end
end
