# frozen_string_literal: true

module PageObjects
  module Pages
    class WorkflowDiscovery < PageObjects::Pages::Base
      def visit_workflow
        page.visit("/workflow")
        self
      end

      def visit_workflow_charts
        page.visit("/workflow/charts")
        self
      end

      def has_quick_filters?
        has_css?(".workflow-quick-filters")
      end

      def select_workflow_view(view_label)
        find(".workflow-quick-filters__view-select").select(view_label)
        self
      end

      def has_workflow_view_option?(view_label)
        has_css?(".workflow-quick-filters__view-select option", text: view_label)
      end

      def has_no_workflow_view_option?(view_label)
        has_no_css?(".workflow-quick-filters__view-select option", text: view_label)
      end

      def has_workflow_burndown_chart?
        has_css?(".workflow-burndown")
      end

      def has_workflow_burndown_chart_canvas?
        has_css?(".workflow-burndown__chart canvas")
      end

      def has_workflow_chart_legend_step?(step_name)
        has_css?(".workflow-burndown__legend .workflow-burndown__legend-step", text: step_name)
      end

      def has_no_workflow_chart_legend_step?(step_name)
        has_no_css?(".workflow-burndown__legend .workflow-burndown__legend-step", text: step_name)
      end

      def has_workflow_chart_weeks_selector?
        has_css?(".workflow-quick-filters__chart-weeks-select")
      end

      def has_chart_weeks_option?(weeks)
        has_css?(
          ".workflow-quick-filters__chart-weeks-select option[value='#{weeks}']",
        )
      end

      def has_view_then_period_order?
        page.evaluate_script(<<~JS)
            (() => {
              const row = document.querySelector(".workflow-quick-filters");
              if (!row) {
                return false;
              }

              const view = row.querySelector(".workflow-quick-filters__view-select");
              const period = row.querySelector(".workflow-quick-filters__chart-weeks-select");
              if (!view || !period) {
                return false;
              }

              return !!(view.compareDocumentPosition(period) & Node.DOCUMENT_POSITION_FOLLOWING);
            })()
          JS
      end

      def has_workflow_chart_workflow_selector?
        has_css?(".workflow-burndown__workflow-select")
      end

      def select_chart_weeks(weeks)
        select = find(".workflow-quick-filters__chart-weeks-select")
        select.find("option[value='#{weeks}']").select_option
        self
      end

      def select_chart_workflow(name)
        find(".workflow-burndown__workflow-select").select(name)
        self
      end

      def workflow_chart_point_count
        find(".workflow-burndown__chart").native["data-point-count"].to_i
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
        has_css?(".workflow-quick-filters__view-select")
      end

      def has_no_workflow_view_toggle?
        has_no_css?(".workflow-quick-filters__view-select")
      end

      def toggle_workflow_view
        select = find(".workflow-quick-filters__view-select")
        select.select(select.value == "kanban" ? "List" : "Kanban")
        self
      end

      def workflow_view_value
        find(".workflow-quick-filters__view-select").value
      end

      def has_kanban_board?
        has_css?(".workflow-kanban")
      end

      def has_kanban_column_for_step?(position)
        has_css?(".workflow-kanban__column[data-workflow-step-position='#{position}']")
      end

      def kanban_column_border_color(position)
        page.evaluate_script(<<~JS)
            (() => {
              const column = document.querySelector(
                '.workflow-kanban__column[data-workflow-step-position="#{position}"]'
              );
              if (!column) {
                return null;
              }

              return window.getComputedStyle(column).borderTopColor;
            })();
          JS
      end

      def has_kanban_card_for_topic?(topic_id)
        has_css?(".workflow-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_no_kanban_card_for_topic?(topic_id)
        has_no_css?(".workflow-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_kanban_card_for_topic_in_step?(topic_id, position)
        has_css?(
          ".workflow-kanban__column[data-workflow-step-position='#{position}'] .workflow-kanban__card[data-topic-id='#{topic_id}']",
        )
      end

      def has_no_kanban_card_for_topic_in_step?(topic_id, position)
        has_no_css?(
          ".workflow-kanban__column[data-workflow-step-position='#{position}'] .workflow-kanban__card[data-topic-id='#{topic_id}']",
        )
      end

      def has_kanban_tag_for_topic?(topic_id, tag_name)
        has_css?(
          ".workflow-kanban__card[data-topic-id='#{topic_id}'] .workflow-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']",
        )
      end

      def has_no_kanban_tag_for_topic?(topic_id, tag_name)
        has_no_css?(
          ".workflow-kanban__card[data-topic-id='#{topic_id}'] .workflow-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']",
        )
      end

      def has_kanban_legal_drop_target_for_step?(position)
        has_css?(".workflow-kanban__column--legal[data-workflow-step-position='#{position}']")
      end

      def has_kanban_illegal_drop_target_for_step?(position)
        has_css?(".workflow-kanban__column--illegal[data-workflow-step-position='#{position}']")
      end

      def drag_kanban_card_to_step(topic_id, position)
        page.execute_script(<<~JS, topic_id, position)
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
        self
      end

      def start_drag_on_kanban_card(topic_id)
        page.execute_script(<<~JS, topic_id)
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
        self
      end

      def end_drag_on_kanban_card(topic_id)
        page.execute_script(<<~JS, topic_id)
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
        self
      end

      def move_kanban_card_with_key(topic_id, key)
        page.execute_script(<<~JS, topic_id, key)
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
        self
      end

      def current_url
        page.current_url
      end
    end
  end
end
