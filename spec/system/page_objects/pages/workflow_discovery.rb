# frozen_string_literal: true

module PageObjects
  module Pages
    class WorkflowDiscovery < PageObjects::Pages::Base
      def visit_workflow
        page.visit("/workflow")
        self
      end

      def has_quick_filters?
        has_css?(".workflow-quick-filters")
      end

      def toggle_my_categories
        find(".workflow-quick-filters__my-categories").click
        self
      end

      def toggle_overdue
        find(".workflow-quick-filters__overdue").click
        self
      end

      def set_step_filter(step)
        find(".workflow-quick-filters__step-input").fill_in(with: step)
        find(".workflow-quick-filters__apply-step").click
        self
      end

      def current_url
        page.current_url
      end
    end
  end
end
