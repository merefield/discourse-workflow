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

      def has_workflow_view_toggle?
        has_css?(".workflow-quick-filters__workflow-view")
      end

      def has_no_workflow_view_toggle?
        has_no_css?(".workflow-quick-filters__workflow-view")
      end

      def toggle_workflow_view
        find(".workflow-quick-filters__workflow-view").click
        self
      end

      def has_kanban_board?
        has_css?(".workflow-kanban")
      end

      def has_kanban_column_for_step?(position)
        has_css?(".workflow-kanban__column[data-workflow-step-position='#{position}']")
      end

      def has_kanban_card_for_topic?(topic_id)
        has_css?(".workflow-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_no_kanban_card_for_topic?(topic_id)
        has_no_css?(".workflow-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_kanban_card_for_topic_in_step?(topic_id, position)
        has_css?(
          ".workflow-kanban__column[data-workflow-step-position='#{position}'] .workflow-kanban__card[data-topic-id='#{topic_id}']"
        )
      end

      def has_no_kanban_card_for_topic_in_step?(topic_id, position)
        has_no_css?(
          ".workflow-kanban__column[data-workflow-step-position='#{position}'] .workflow-kanban__card[data-topic-id='#{topic_id}']"
        )
      end

      def has_kanban_tag_for_topic?(topic_id, tag_name)
        has_css?(
          ".workflow-kanban__card[data-topic-id='#{topic_id}'] .workflow-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']"
        )
      end

      def has_no_kanban_tag_for_topic?(topic_id, tag_name)
        has_no_css?(
          ".workflow-kanban__card[data-topic-id='#{topic_id}'] .workflow-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']"
        )
      end

      def has_kanban_legal_drop_target_for_step?(position)
        has_css?(
          ".workflow-kanban__column--legal[data-workflow-step-position='#{position}']"
        )
      end

      def has_kanban_illegal_drop_target_for_step?(position)
        has_css?(
          ".workflow-kanban__column--illegal[data-workflow-step-position='#{position}']"
        )
      end

      def drag_kanban_card_to_step(topic_id, position)
        page.execute_script(
          <<~JS,
            const topicId = arguments[0];
            const stepPosition = arguments[1];
            const card = document.querySelector(
              `.workflow-kanban__card[data-topic-id="${topicId}"]`
            );
            const target = document.querySelector(
              `.workflow-kanban__column[data-workflow-step-position="${stepPosition}"] .workflow-kanban__cards`
            );

            if (!card || !target) {
              return;
            }

            const dataTransfer = new DataTransfer();
            card.dispatchEvent(
              new DragEvent("dragstart", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            target.dispatchEvent(
              new DragEvent("dragover", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            target.dispatchEvent(
              new DragEvent("drop", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            card.dispatchEvent(
              new DragEvent("dragend", {
                bubbles: true,
                cancelable: true,
              })
            );
          JS
          topic_id,
          position
        )
        self
      end

      def start_drag_on_kanban_card(topic_id)
        page.execute_script(
          <<~JS,
            const topicId = arguments[0];
            const card = document.querySelector(
              `.workflow-kanban__card[data-topic-id="${topicId}"]`
            );

            if (!card) {
              return;
            }

            const dataTransfer = new DataTransfer();
            const event = new DragEvent("dragstart", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
            });
            card.dispatchEvent(event);
          JS
          topic_id
        )
        self
      end

      def end_drag_on_kanban_card(topic_id)
        page.execute_script(
          <<~JS,
            const topicId = arguments[0];
            const card = document.querySelector(
              `.workflow-kanban__card[data-topic-id="${topicId}"]`
            );

            if (!card) {
              return;
            }

            const event = new DragEvent("dragend", {
              bubbles: true,
              cancelable: true,
            });
            card.dispatchEvent(event);
          JS
          topic_id
        )
        self
      end

      def move_kanban_card_with_key(topic_id, key)
        page.execute_script(
          <<~JS,
            const id = arguments[0];
            const key = arguments[1];
            const card = document.querySelector(
              `.workflow-kanban__card[data-topic-id="${id}"]`
            );

            if (!card) {
              return;
            }

            card.focus();
            card.dispatchEvent(
              new KeyboardEvent("keydown", {
                key,
                bubbles: true,
                cancelable: true,
              })
            );
          JS
          topic_id,
          key
        )
        self
      end

      def current_url
        page.current_url
      end
    end
  end
end
