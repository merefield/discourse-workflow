# frozen_string_literal: true

module PageObjects
  module Pages
    class WorkflowAdminVisual < PageObjects::Pages::Base
      def visit_workflow(workflow)
        page.visit "/admin/plugins/discourse-workflow/workflows/#{workflow.id}/edit"
        self
      end

      def switch_to_visual
        click_button "Visual"
        self
      end

      def has_steps_tab?(label)
        has_css?(".workflow-editor__steps-tab", text: label)
      end

      def has_visual?
        has_css?(".workflow-visual-editor")
      end

      def has_step?(step, text: nil)
        options = text ? { text: text } : {}
        has_css?(step_selector(step), **options)
      end

      def has_no_step?(step)
        has_no_css?(step_selector(step))
      end

      def has_lane?(category, text: nil)
        options = text ? { text: text } : {}
        has_css?(lane_selector(category), **options)
      end

      def has_no_lane?(category)
        has_no_css?(lane_selector(category))
      end

      def add_step_from_lane(category)
        within(lane_selector(category)) { find(".workflow-visual-editor__add-step-to-lane").click }

        self
      end

      def has_new_step_editor?
        has_css?(".workflow-step-editor")
      end

      def has_new_step_category?(category)
        has_current_path?(/category_id=#{category.id}/) &&
          has_css?(".workflow-step-editor", text: category.name)
      end

      def has_step_in_lane?(step, category)
        has_css?("#{lane_selector(category)} #{step_selector(step)}")
      end

      def has_step_in_lane_position?(step, category, position)
        has_css?("#{position_selector(category, position)} #{step_selector(step)}")
      end

      def has_step_width_ratio?(step, ratio)
        has_css?(step_selector(step)) && page.evaluate_script(<<~JS, step.id, ratio)
          (() => {
            const stepId = arguments[0];
            const expectedRatio = arguments[1];
            const step = document.querySelector(`.workflow-visual-editor__step[data-workflow-step-id="${stepId}"]`);
            const slot = step.closest(".workflow-visual-editor__position-slot");
            const stepRect = step.getBoundingClientRect();
            const slotRect = slot.getBoundingClientRect();
            const actualRatio = stepRect.width / slotRect.width;

            return Math.abs(actualRatio - expectedRatio) < 0.05;
          })();
        JS
      end

      def has_centered_step_label?(step)
        has_css?(step_selector(step)) && page.evaluate_script(<<~JS, step.id)
          (() => {
            const stepId = arguments[0];
            const step = document.querySelector(`.workflow-visual-editor__step[data-workflow-step-id="${stepId}"]`);
            const number = step.querySelector(".workflow-visual-editor__step-number");
            const label = step.querySelector(".workflow-visual-editor__step-label");
            const stepRect = step.getBoundingClientRect();
            const labelRect = label.getBoundingClientRect();
            const stepCenter = stepRect.left + stepRect.width / 2;
            const labelCenter = labelRect.left + labelRect.width / 2;

            return number && label && Math.abs(stepCenter - labelCenter) <= 2;
          })();
        JS
      end

      def has_step_centered_in_lane_content?(step)
        has_css?(step_selector(step)) && page.evaluate_script(<<~JS, step.id)
          (() => {
            const stepId = arguments[0];
            const step = document.querySelector(`.workflow-visual-editor__step[data-workflow-step-id="${stepId}"]`);
            const laneContent = step.closest(".workflow-visual-editor__lane-steps");
            const stepRect = step.getBoundingClientRect();
            const laneContentRect = laneContent.getBoundingClientRect();
            const stepCenter = stepRect.top + stepRect.height / 2;
            const laneContentCenter = laneContentRect.top + laneContentRect.height / 2;
            const laneContentStyle = window.getComputedStyle(laneContent);

            return Math.abs(stepCenter - laneContentCenter) <= 2 &&
              laneContentStyle.paddingTop === "0px";
          })();
        JS
      end

      def has_option?(step_option, text: nil)
        options = text ? { text: text } : {}
        has_css?(option_selector(step_option), **options)
      end

      def has_any_option?(text:)
        has_css?(".workflow-visual-editor__option", text: text)
      end

      def has_any_option_control?
        has_css?(".workflow-visual-editor__option")
      end

      def has_no_new_arrow_option_control?
        has_no_css?(".workflow-visual-editor__link-option") && has_no_content?("New arrow option")
      end

      def has_connector_handles?(step)
        %w[top right bottom left].all? do |side|
          has_css?(
            "#{connector_handle_selector(step, side)}[aria-label='#{side.capitalize} connector handle for #{step.name}']",
          )
        end
      end

      def has_native_drag_payloads_for?(step)
        has_css?(step_selector(step)) &&
          drag_start_payload(step_selector(step)) == "workflow-step:#{step.id}" &&
          drag_start_payload(connector_handle_selector(step, "right")) ==
            "workflow-connector:#{step.id}:right"
      end

      def has_selected_connector_handle?(step, side)
        has_css?(
          "#{connector_handle_selector(step, side)}.workflow-visual-editor__connector-handle--selected[aria-pressed='true']",
        )
      end

      def has_arrow_link_for_option?(step_option)
        has_css?("#{option_selector(step_option)}") &&
          has_css?(".workflow-visual-editor__edge-path")
      end

      def has_only_orthogonal_arrow_paths?
        has_css?(".workflow-visual-editor__edge-path") &&
          all(".workflow-visual-editor__edge-path").all? do |path|
            path["d"].exclude?("C") && path["d"].exclude?("Q")
          end
      end

      def has_forward_arrow_path?
        has_css?(".workflow-visual-editor__edge-path") &&
          all(".workflow-visual-editor__edge-path").any? do |path|
            path["d"].include?(" H") && path["d"].include?(" V")
          end
      end

      def has_no_arrow_crossing_step_boxes?
        has_css?(".workflow-visual-editor__edge-path") && page.evaluate_script(<<~JS)
            (() => {
            const parsePathSegments = (path) => {
              const tokens = path.getAttribute("d").match(/[MLHV]|-?\\d+(?:\\.\\d+)?/g) || [];
              const segments = [];
              let index = 0;
              let command = null;
              let current = { x: 0, y: 0 };

              while (index < tokens.length) {
                const token = tokens[index++];
                if (["M", "L", "H", "V"].includes(token)) {
                  command = token;
                } else {
                  index--;
                }

                if (command === "M") {
                  current = { x: Number(tokens[index++]), y: Number(tokens[index++]) };
                } else if (command === "L") {
                  const next = { x: Number(tokens[index++]), y: Number(tokens[index++]) };
                  segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                  current = next;
                } else if (command === "H") {
                  const next = { x: Number(tokens[index++]), y: current.y };
                  segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                  current = next;
                } else if (command === "V") {
                  const next = { x: current.x, y: Number(tokens[index++]) };
                  segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                  current = next;
                }
              }

              return segments;
            };
            const intersects = (segment, rect) => {
              const padding = 6;
              const left = rect.left + padding;
              const right = rect.right - padding;
              const top = rect.top + padding;
              const bottom = rect.bottom - padding;
              const minX = Math.min(segment.x1, segment.x2);
              const maxX = Math.max(segment.x1, segment.x2);
              const minY = Math.min(segment.y1, segment.y2);
              const maxY = Math.max(segment.y1, segment.y2);

              if (segment.y1 === segment.y2) {
                return segment.y1 >= top && segment.y1 <= bottom && maxX >= left && minX <= right;
              }

              if (segment.x1 === segment.x2) {
                return segment.x1 >= left && segment.x1 <= right && maxY >= top && minY <= bottom;
              }

              return false;
            };
            const boardRect = document.querySelector(".workflow-visual-editor__board").getBoundingClientRect();
            const stepRects = Array.from(document.querySelectorAll(".workflow-visual-editor__step")).map((step) => {
              const rect = step.getBoundingClientRect();
              return {
                id: step.dataset.workflowStepId,
                left: rect.left - boardRect.left,
                right: rect.right - boardRect.left,
                top: rect.top - boardRect.top,
                bottom: rect.bottom - boardRect.top,
              };
            });

            return Array.from(document.querySelectorAll(".workflow-visual-editor__edge-path")).every((path) => {
              const endpointStepIds = [path.dataset.workflowSourceStepId, path.dataset.workflowTargetStepId];

              return parsePathSegments(path).every((segment) => {
                return stepRects.every((rect) => endpointStepIds.includes(rect.id) || !intersects(segment, rect));
              });
            });
            })();
          JS
      end

      def has_no_overlapping_arrow_segments?
        has_css?(".workflow-visual-editor__edge-path") && page.evaluate_script(<<~JS)
          (() => {
            #{path_geometry_helpers}

            const overlaps = (segment, otherSegment) => {
              const rangesOverlap = (start, end, otherStart, otherEnd) => {
                const min = Math.min(start, end);
                const max = Math.max(start, end);
                const otherMin = Math.min(otherStart, otherEnd);
                const otherMax = Math.max(otherStart, otherEnd);
                return Math.max(min, otherMin) < Math.min(max, otherMax);
              };

              if (segment.y1 === segment.y2 && otherSegment.y1 === otherSegment.y2) {
                return segment.y1 === otherSegment.y1 && rangesOverlap(segment.x1, segment.x2, otherSegment.x1, otherSegment.x2);
              }

              if (segment.x1 === segment.x2 && otherSegment.x1 === otherSegment.x2) {
                return segment.x1 === otherSegment.x1 && rangesOverlap(segment.y1, segment.y2, otherSegment.y1, otherSegment.y2);
              }

              return false;
            };
            const segments = Array.from(document.querySelectorAll(".workflow-visual-editor__edge-path")).flatMap((path, pathIndex) => {
              return parsePathSegments(path).map((segment) => ({ ...segment, pathIndex }));
            });

            return segments.every((segment, index) => {
              return segments.slice(index + 1).every((otherSegment) => {
                return segment.pathIndex === otherSegment.pathIndex || !overlaps(segment, otherSegment);
              });
            });
          })();
        JS
      end

      def has_no_double_back_arrow_paths?
        has_css?(".workflow-visual-editor__edge-path") && page.evaluate_script(<<~JS)
          (() => {
            #{path_geometry_helpers}

            const doublesBack = (segments) => {
              return segments.slice(1).some((segment, index) => {
                const previous = segments[index];
                const bothHorizontal = previous.y1 === previous.y2 && segment.y1 === segment.y2;
                const bothVertical = previous.x1 === previous.x2 && segment.x1 === segment.x2;

                if (bothHorizontal && previous.y1 === segment.y1) {
                  return Math.sign(previous.x2 - previous.x1) !== Math.sign(segment.x2 - segment.x1);
                }

                if (bothVertical && previous.x1 === segment.x1) {
                  return Math.sign(previous.y2 - previous.y1) !== Math.sign(segment.y2 - segment.y1);
                }

                return false;
              });
            };

            return Array.from(document.querySelectorAll(".workflow-visual-editor__edge-path")).every((path) => {
              return !doublesBack(parsePathSegments(path));
            });
          })();
        JS
      end

      def has_arrow_paths_within_lane_stack?
        has_css?(".workflow-visual-editor__edge-path") && page.evaluate_script(<<~JS)
          (() => {
            #{path_geometry_helpers}

            const boardRect = document.querySelector(".workflow-visual-editor__board").getBoundingClientRect();
            const laneBounds = Array.from(document.querySelectorAll(".workflow-visual-editor__lane")).map((lane) => {
              const rect = lane.getBoundingClientRect();
              return {
                top: rect.top - boardRect.top,
                bottom: rect.bottom - boardRect.top,
              };
            });
            const top = Math.min(...laneBounds.map((bound) => bound.top));
            const bottom = Math.max(...laneBounds.map((bound) => bound.bottom));

            return Array.from(document.querySelectorAll(".workflow-visual-editor__edge-path")).every((path) => {
              return parsePathSegments(path).every((segment) => {
                return segment.y1 >= top && segment.y1 <= bottom && segment.y2 >= top && segment.y2 <= bottom;
              });
            });
          })();
        JS
      end

      def has_no_arrow_travelling_along_lane_borders?
        has_css?(".workflow-visual-editor__edge-path") && page.evaluate_script(<<~JS)
          (() => {
            #{path_geometry_helpers}

            const boardRect = document.querySelector(".workflow-visual-editor__board").getBoundingClientRect();
            const laneBounds = Array.from(document.querySelectorAll(".workflow-visual-editor__lane")).map((lane) => {
              const rect = lane.getBoundingClientRect();
              return {
                left: rect.left - boardRect.left,
                right: rect.right - boardRect.left,
                top: rect.top - boardRect.top,
                bottom: rect.bottom - boardRect.top,
              };
            });
            const overlaps = (segment, lane) => {
              const travelsAlongLaneEdge = Math.abs(segment.y1 - lane.top) <= 2 ||
                Math.abs(segment.y1 - lane.bottom) <= 2;

              if (segment.y1 !== segment.y2 || !travelsAlongLaneEdge) {
                return false;
              }

              const segmentLeft = Math.min(segment.x1, segment.x2);
              const segmentRight = Math.max(segment.x1, segment.x2);
              return Math.min(segmentRight, lane.right) > Math.max(segmentLeft, lane.left);
            };

            return Array.from(document.querySelectorAll(".workflow-visual-editor__edge-path")).every((path) => {
              return parsePathSegments(path).every((segment) => {
                return laneBounds.every((lane) => !overlaps(segment, lane));
              });
            });
          })();
        JS
      end

      def has_option_on_longest_vertical_segment?(step_option)
        has_css?(option_selector(step_option)) && page.evaluate_script(<<~JS, step_option.id)
          (() => {
            #{path_geometry_helpers}

            const stepOptionId = arguments[0];
            const path = document.querySelector(`.workflow-visual-editor__edge-path[data-workflow-step-option-id="${stepOptionId}"]`);
            const option = document.querySelector(`.workflow-visual-editor__option[data-workflow-step-option-id="${stepOptionId}"]`);
            const boardRect = document.querySelector(".workflow-visual-editor__board").getBoundingClientRect();
            const optionRect = option.getBoundingClientRect();
            const optionCenter = {
              x: optionRect.left - boardRect.left + optionRect.width / 2,
              y: optionRect.top - boardRect.top + optionRect.height / 2,
            };
            const verticalSegments = parsePathSegments(path).filter((segment) => segment.x1 === segment.x2);
            const laneCenters = Array.from(document.querySelectorAll(".workflow-visual-editor__lane")).map((lane) => {
              const laneRect = lane.getBoundingClientRect();
              const headerRect = lane.querySelector(".workflow-visual-editor__lane-header")?.getBoundingClientRect();

              return {
                xLeft: laneRect.left - boardRect.left,
                xRight: laneRect.right - boardRect.left,
                y: ((headerRect || laneRect).bottom + laneRect.bottom) / 2 - boardRect.top,
              };
            });

            if (!verticalSegments.length) {
              return true;
            }

            const candidateRatios = [0.5, 1 / 3, 2 / 3, 0.25, 0.75, 0.2, 0.8, 0.1, 0.9, 0.05];

            return verticalSegments.some((segment) => {
              const startY = Math.min(segment.y1, segment.y2);
              const endY = Math.max(segment.y1, segment.y2);
              const length = endY - startY;
              const onSegmentX = Math.abs(optionCenter.x - segment.x1) <= 3;
              const onRatioCandidate = candidateRatios.some((ratio) => {
                return Math.abs(optionCenter.y - (startY + length * ratio)) <= 3;
              });
              const onLaneCenterCandidate = laneCenters.some((laneCenter) => {
                return segment.x1 >= laneCenter.xLeft &&
                  segment.x1 <= laneCenter.xRight &&
                  laneCenter.y >= startY &&
                  laneCenter.y <= endY &&
                  Math.abs(optionCenter.y - laneCenter.y) <= 3;
              });

              return onSegmentX && (onRatioCandidate || onLaneCenterCandidate);
            });
          })();
        JS
      end

      def has_no_overlapping_option_dropdowns?
        has_css?(".workflow-visual-editor__option") && page.evaluate_script(<<~JS)
          (() => {
            const rects = Array.from(document.querySelectorAll(".workflow-visual-editor__option")).map((option) => {
              const rect = option.getBoundingClientRect();
              return {
                left: rect.left,
                right: rect.right,
                top: rect.top,
                bottom: rect.bottom,
              };
            });
            const overlaps = (rect, otherRect) => {
              return Math.max(rect.left, otherRect.left) < Math.min(rect.right, otherRect.right) &&
                Math.max(rect.top, otherRect.top) < Math.min(rect.bottom, otherRect.bottom);
            };

            return rects.every((rect, index) => {
              return rects.slice(index + 1).every((otherRect) => !overlaps(rect, otherRect));
            });
          })();
        JS
      end

      def has_no_option_dropdown_over_step_boxes_for?(step_option)
        has_css?(option_selector(step_option)) && page.evaluate_script(<<~JS, step_option.id)
          (() => {
            const stepOptionId = arguments[0];
            const overlaps = (rect, otherRect) => {
              return Math.max(rect.left, otherRect.left) < Math.min(rect.right, otherRect.right) &&
                Math.max(rect.top, otherRect.top) < Math.min(rect.bottom, otherRect.bottom);
            };
            const option = document.querySelector(`.workflow-visual-editor__option[data-workflow-step-option-id="${stepOptionId}"]`);
            const optionRect = option.getBoundingClientRect();
            const stepRects = Array.from(document.querySelectorAll(".workflow-visual-editor__step")).map((step) => {
              return step.getBoundingClientRect();
            });

            return stepRects.every((stepRect) => !overlaps(optionRect, stepRect));
          })();
        JS
      end

      def has_forward_arrow_from_right_edge?(step_option)
        has_css?(
          ".workflow-visual-editor__edge-path[data-workflow-step-option-id='#{step_option.id}'][data-workflow-source-side='right']",
        )
      end

      def drag_connector(source_step, target_step)
        drag(unconnected_handle_selector(source_step), unconnected_handle_selector(target_step))
        self
      end

      def click_connector_handle(step, side)
        find(connector_handle_selector(step, side)).click
        self
      end

      def drag_existing_connector_target(current_target_step, new_target_step)
        drag(
          connected_handle_selector(current_target_step),
          unconnected_handle_selector(new_target_step),
        )
        self
      end

      def drag_step_to_lane_position(step, category, position)
        drag(step_selector(step), position_selector(category, position))
        self
      end

      def fill_new_step_name(name)
        find(".workflow-visual-editor__new-step-name").fill_in(with: name)
        self
      end

      def choose_new_step_category(category)
        PageObjects::Components::SelectKit.new(
          ".workflow-visual-editor__add-step .category-chooser",
        ).select_row_by_value(category.id)
        self
      end

      def add_step
        click_button "Add step"
        self
      end

      def select_option(step_option, workflow_option)
        find(
          "#{option_selector(step_option)} select[data-workflow-step-option-id='#{step_option.id}']",
        ).find("option[value='#{workflow_option.id}']").select_option
        self
      end

      def track_requests
        page.execute_script(<<~JS)
          window.__workflowRequestUrls = [];

          if (!window.__workflowRequestTrackingInstalled) {
            const originalFetch = window.fetch;
            if (originalFetch) {
              window.fetch = function(input, ...args) {
                const url = input?.url || input;
                window.__workflowRequestUrls.push(String(url));
                return originalFetch.call(this, input, ...args);
              };
            }

            const originalOpen = window.XMLHttpRequest.prototype.open;
            window.XMLHttpRequest.prototype.open = function(method, url, ...args) {
              window.__workflowRequestUrls.push(String(url));
              return originalOpen.call(this, method, url, ...args);
            };

            window.__workflowRequestTrackingInstalled = true;
          }
        JS

        self
      end

      def has_tracked_request?(url_fragment)
        page.evaluate_script(<<~JS, url_fragment)
          (window.__workflowRequestUrls || []).some((url) => url.includes(arguments[0]))
        JS
      end

      def tracked_request_count(url_fragment)
        page.evaluate_script(<<~JS, url_fragment)
          (window.__workflowRequestUrls || []).filter((url) => url.includes(arguments[0])).length
        JS
      end

      def make_page_scrollable
        page.execute_script("document.documentElement.style.minHeight = '2400px'")
        self
      end

      def scroll_window_to(offset)
        page.execute_script("window.scrollTo(0, arguments[0])", offset)
        self
      end

      def window_scroll_y
        page.evaluate_script("window.scrollY")
      end

      def has_window_scroll_y?(offset)
        page.document.synchronize do
          if page.evaluate_script("Math.abs(window.scrollY - arguments[0]) <= 2", offset)
            return true
          end

          raise Capybara::ExpectationNotMet
        end
      rescue Capybara::ExpectationNotMet
        false
      end

      def delete_option(step_option)
        find("#{option_selector(step_option)} .workflow-visual-editor__delete-option").click
        self
      end

      def delete_step(step)
        find("#{step_selector(step)} .workflow-visual-editor__delete-step").click
        self
      end

      def has_delete_connector_confirmation?
        has_css?(
          ".dialog-body",
          text: "Are you sure you want to permanently delete this connector?",
        )
      end

      def confirm_delete_connector
        find(".dialog-footer .btn-danger").click
        self
      end

      def has_delete_step_confirmation?
        has_css?(
          ".dialog-body",
          text: "Are you sure you want to permanently delete this step and all related connectors?",
        )
      end

      def confirm_delete_step
        find(".dialog-footer .btn-danger").click
        self
      end

      private

      def step_selector(step)
        ".workflow-visual-editor__step[data-workflow-step-id='#{step.id}']"
      end

      def lane_selector(category)
        ".workflow-visual-editor__lane[data-workflow-category-id='#{category.id}']"
      end

      def position_selector(category, position)
        ".workflow-visual-editor__position-slot[data-workflow-category-id='#{category.id}'][data-workflow-position='#{position}']"
      end

      def option_selector(step_option)
        ".workflow-visual-editor__option[data-workflow-step-option-id='#{step_option.id}']"
      end

      def connector_handle_selector(step, side)
        "#{step_selector(step)} .workflow-visual-editor__connector-handle--#{side}"
      end

      def connected_handle_selector(step)
        "#{step_selector(step)} .workflow-visual-editor__connector-handle--connected"
      end

      def unconnected_handle_selector(step)
        "#{step_selector(step)} .workflow-visual-editor__connector-handle:not(.workflow-visual-editor__connector-handle--connected)"
      end

      def path_geometry_helpers
        <<~JS
          const parsePathSegments = (path) => {
            const tokens = path.getAttribute("d").match(/[MLHV]|-?\\d+(?:\\.\\d+)?/g) || [];
            const segments = [];
            let index = 0;
            let command = null;
            let current = { x: 0, y: 0 };

            while (index < tokens.length) {
              const token = tokens[index++];
              if (["M", "L", "H", "V"].includes(token)) {
                command = token;
              } else {
                index--;
              }

              if (command === "M") {
                current = { x: Number(tokens[index++]), y: Number(tokens[index++]) };
              } else if (command === "L") {
                const next = { x: Number(tokens[index++]), y: Number(tokens[index++]) };
                segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                current = next;
              } else if (command === "H") {
                const next = { x: Number(tokens[index++]), y: current.y };
                segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                current = next;
              } else if (command === "V") {
                const next = { x: current.x, y: Number(tokens[index++]) };
                segments.push({ x1: current.x, y1: current.y, x2: next.x, y2: next.y });
                current = next;
              }
            }

            return segments;
          };
        JS
      end

      def drag(source_selector, target_selector)
        page.execute_script(<<~JS, source_selector, target_selector)
          const source = document.querySelector(arguments[0]);
          const target = document.querySelector(arguments[1]);
          const dataTransfer = new DataTransfer();
          const sourceRect = source.getBoundingClientRect();
          const targetRect = target.getBoundingClientRect();

          source.dispatchEvent(
            new DragEvent("dragstart", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
              clientX: sourceRect.left + sourceRect.width / 2,
              clientY: sourceRect.top + sourceRect.height / 2,
            })
          );

          target.dispatchEvent(
            new DragEvent("dragover", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
              clientX: targetRect.left + targetRect.width / 2,
              clientY: targetRect.top + targetRect.height / 2,
            })
          );

          target.dispatchEvent(
            new DragEvent("drop", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
              clientX: targetRect.left + targetRect.width / 2,
              clientY: targetRect.top + targetRect.height / 2,
            })
          );

          source.dispatchEvent(
            new DragEvent("dragend", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
            })
          );
        JS
      end

      def drag_start_payload(selector)
        page.evaluate_script(<<~JS, selector)
          (() => {
            const source = document.querySelector(arguments[0]);
            const dataTransfer = new DataTransfer();
            const sourceRect = source.getBoundingClientRect();

            source.dispatchEvent(
              new DragEvent("dragstart", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
                clientX: sourceRect.left + sourceRect.width / 2,
                clientY: sourceRect.top + sourceRect.height / 2,
              })
            );

            source.dispatchEvent(
              new DragEvent("dragend", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );

            return dataTransfer.getData("text/plain");
          })();
        JS
      end
    end
  end
end
