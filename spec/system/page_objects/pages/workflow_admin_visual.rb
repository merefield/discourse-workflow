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
        %w[top right bottom left].all? { |side| has_css?(connector_handle_selector(step, side)) }
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

      def has_crossing_penalty_without_forbidding_routes?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const crossingSegments = [{ x1: 0, y1: 10, x2: 20, y2: 10 }];
            const routedSegments = [{ x1: 10, y1: 0, x2: 10, y2: 20 }];
            const scoreFor = (segments, existingSegments, arrowheadPoints = []) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 20, y: 20 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: existingSegments,
                routedLabels: [],
                arrowheadPoints,
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const scoreWithoutCrossing = scoreFor(crossingSegments, []);
            const scoreWithCrossing = scoreFor(crossingSegments, routedSegments);
            const scoreWithOverlap = scoreFor(
              [{ x1: 0, y1: 10, x2: 20, y2: 10 }],
              [{ x1: 10, y1: 10, x2: 30, y2: 10 }]
            );

            return Number.isFinite(scoreWithCrossing) &&
              scoreWithCrossing > scoreWithoutCrossing &&
              scoreWithOverlap === Infinity;
          })();
        JS
      end

      def has_arrowhead_label_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const segments = [{ x1: 0, y1: 10, x2: 20, y2: 10 }];
            const scoreFor = (arrowheadPoints) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 20, y: 20 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints,
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const scoreWithoutArrowheadCover = scoreFor([{ x: 300, y: 300 }]);
            const scoreWithArrowheadCover = scoreFor([{ x: 20, y: 20 }]);

            return Number.isFinite(scoreWithArrowheadCover) &&
              scoreWithArrowheadCover > scoreWithoutArrowheadCover;
          })();
        JS
      end

      def has_connector_line_label_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const segments = [{ x1: 0, y1: 10, x2: 20, y2: 10 }];
            const scoreFor = (routedSegments) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 20, y: 20 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments,
                routedLabels: [],
                arrowheadPoints: [],
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const scoreWithoutLineCover = scoreFor([{ x1: 300, y1: 300, x2: 320, y2: 300 }]);
            const scoreWithLineCover = scoreFor([{ x1: 10, y1: 20, x2: 30, y2: 20 }]);

            return Number.isFinite(scoreWithLineCover) &&
              scoreWithLineCover > scoreWithoutLineCover;
          })();
        JS
      end

      def has_horizontal_connector_under_dropdown_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreFor = (routedLabels) => {
              return editor.routeCandidateScore({
                segments: [{ x1: 0, y1: 20, x2: 100, y2: 20 }],
                labelPoint: { x: 500, y: 500 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels,
                arrowheadPoints: [],
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const scoreWithoutDropdownCover = scoreFor([{ x: 300, y: 300 }]);
            const scoreWithDropdownCover = scoreFor([{ x: 50, y: 20 }]);

            return Number.isFinite(scoreWithDropdownCover) &&
              scoreWithDropdownCover > scoreWithoutDropdownCover;
          })();
        JS
      end

      def has_label_penalties_restored_for_return_connectors?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreWithLabelPenalties = editor.routeCandidateScore({
              segments: [{ x1: 0, y1: 10, x2: 20, y2: 10 }],
              labelPoint: { x: 20, y: 20 },
              obstacleRects: [],
              labelObstacleRects: [{ left: 0, right: 40, top: 0, bottom: 40 }],
              routedSegments: [{ x1: 10, y1: 20, x2: 30, y2: 20 }],
              routedLabels: [],
              arrowheadPoints: [{ x: 20, y: 20 }],
              laneStackBounds: null,
              sidePenalty: 0,
            });
            const scoreWithoutLabelPenalties = editor.routeCandidateScore({
              segments: [{ x1: 0, y1: 10, x2: 20, y2: 10 }],
              labelPoint: { x: 300, y: 300 },
              obstacleRects: [],
              labelObstacleRects: [],
              routedSegments: [{ x1: 500, y1: 500, x2: 520, y2: 500 }],
              routedLabels: [],
              arrowheadPoints: [],
              laneStackBounds: null,
              sidePenalty: 0,
            });

            return Number.isFinite(scoreWithLabelPenalties) &&
              scoreWithLabelPenalties > scoreWithoutLabelPenalties;
          })();
        JS
      end

      def has_own_arrowhead_included_in_label_penalties?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const originalRouteCandidateScore = editor.routeCandidateScore.bind(editor);
            let ownArrowheadIncluded = false;

            editor.routeCandidateScore = (options) => {
              ownArrowheadIncluded ||= options.arrowheadPoints.some((arrowheadPoint) => {
                return arrowheadPoint.x === 20 && arrowheadPoint.y === 10;
              });

              return originalRouteCandidateScore(options);
            };

            editor.routePoints({
              index: 0,
              source: { x: 0, y: 10 },
              sourceSide: "right",
              target: { x: 20, y: 10 },
              targetSide: "left",
              obstacleRects: [],
              labelObstacleRects: [],
              routedSegments: [],
              routedLabels: [],
              routedArrowheads: [],
              laneStackBounds: null,
              sidePenalty: 0,
            });

            return ownArrowheadIncluded;
          })();
        JS
      end

      def has_other_arrowhead_label_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreFor = (arrowheadPoints) => {
              return editor.routeCandidateScore({
                segments: [{ x1: 0, y1: 10, x2: 20, y2: 10 }],
                labelPoint: { x: 20, y: 20 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints,
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const scoreWithoutArrowheadCover = scoreFor([{ x: 300, y: 300 }]);
            const scoreWithArrowheadCover = scoreFor([{ x: 20, y: 20 }]);

            return Number.isFinite(scoreWithArrowheadCover) &&
              scoreWithArrowheadCover > scoreWithoutArrowheadCover;
          })();
        JS
      end

      def has_midpoint_label_preference?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const candidates = editor.labelCandidatesForSegments([
              { x1: 20, y1: 0, x2: 20, y2: 90 },
            ]);

            return candidates[0].point.y === 45 &&
              candidates[0].penalty === 0 &&
              candidates[1].point.y === 30 &&
              candidates[1].penalty > 0 &&
              candidates[2].point.y === 60 &&
              candidates[2].penalty > 0 &&
              candidates[3].point.y === 22.5 &&
              candidates[3].penalty > candidates[1].penalty &&
              candidates[4].point.y === 67.5 &&
              candidates[4].penalty > candidates[2].penalty &&
              candidates[5].point.y === 18 &&
              candidates[5].penalty > candidates[3].penalty &&
              candidates[6].point.y === 72 &&
              candidates[6].penalty > candidates[4].penalty &&
              candidates[7].point.y === 9 &&
              candidates[7].penalty > candidates[5].penalty &&
              candidates[8].point.y === 81 &&
              candidates[8].penalty > candidates[6].penalty;
          })();
        JS
      end

      def has_alternate_label_position_can_win?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const route = editor.routePoints({
              index: 0,
              source: { x: 0, y: 0 },
              sourceSide: "right",
              target: { x: 40, y: 90 },
              targetSide: "left",
              obstacleRects: [],
              labelObstacleRects: [{ left: 8, right: 32, top: 34, bottom: 56 }],
              routedSegments: [],
              routedLabels: [],
              routedArrowheads: [],
              laneStackBounds: null,
              sidePenalty: 0,
            });

            return route.label_y !== 45;
          })();
        JS
      end

      def has_label_lane_boundary_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreFor = (labelPoint) => {
              return editor.routeCandidateScore({
                segments: [{ x1: 0, y1: 50, x2: 100, y2: 50 }],
                labelPoint,
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints: [],
                laneStackBounds: {
                  top: 0,
                  bottom: 180,
                  lanes: [
                    {
                      left: 0,
                      right: 200,
                      top: 40,
                      bottom: 180,
                      labelTop: 40,
                      labelBottom: 62,
                    },
                  ],
                },
                sidePenalty: 0,
              });
            };
            const scoreWithoutBoundaryOverlap = scoreFor({ x: 100, y: 100 });
            const scoreWithBoundaryOverlap = scoreFor({ x: 100, y: 180 });
            const scoreWithLaneLabelOverlap = scoreFor({ x: 100, y: 52 });

            return Number.isFinite(scoreWithBoundaryOverlap) &&
              scoreWithBoundaryOverlap > scoreWithoutBoundaryOverlap &&
              scoreWithLaneLabelOverlap > scoreWithBoundaryOverlap;
          })();
        JS
      end

      def has_lane_gap_travel_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const laneStackBounds = {
              top: 0,
              bottom: 220,
              lanes: [
                { left: 0, right: 200, top: 0, bottom: 100 },
                { left: 0, right: 200, top: 120, bottom: 220 },
              ],
            };
            const penaltyInLane = editor.laneGapTravelPenalty(
              [{ x1: 0, y1: 80, x2: 100, y2: 80 }],
              laneStackBounds
            );
            const penaltyBetweenLanes = editor.laneGapTravelPenalty(
              [{ x1: 0, y1: 110, x2: 100, y2: 110 }],
              laneStackBounds
            );
            const penaltyCrossingGap = editor.laneGapTravelPenalty(
              [{ x1: 50, y1: 80, x2: 50, y2: 140 }],
              laneStackBounds
            );

            return penaltyInLane === 0 &&
              penaltyBetweenLanes > 0 &&
              penaltyCrossingGap === 0;
          })();
        JS
      end

      def has_turn_count_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreFor = (segments) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 300, y: 300 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints: [],
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const simpleRoute = [{ x1: 0, y1: 0, x2: 100, y2: 0 }];
            const sameLengthRouteWithTurns = [
              { x1: 0, y1: 0, x2: 25, y2: 0 },
              { x1: 25, y1: 0, x2: 25, y2: 25 },
              { x1: 25, y1: 25, x2: 75, y2: 25 },
              { x1: 75, y1: 25, x2: 75, y2: 0 },
              { x1: 75, y1: 0, x2: 100, y2: 0 },
            ];

            return scoreFor(sameLengthRouteWithTurns) > scoreFor(simpleRoute);
          })();
        JS
      end

      def has_short_segment_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const scoreFor = (segments) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 300, y: 300 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints: [],
                laneStackBounds: null,
                sidePenalty: 0,
              });
            };
            const longSegment = [{ x1: 0, y1: 0, x2: 100, y2: 0 }];
            const sameLengthWithShortSegments = [
              { x1: 0, y1: 0, x2: 20, y2: 0 },
              { x1: 20, y1: 0, x2: 100, y2: 0 },
            ];

            return scoreFor(sameLengthWithShortSegments) > scoreFor(longSegment);
          })();
        JS
      end

      def has_lower_return_route_length_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const segments = [{ x1: 0, y1: 0, x2: 100, y2: 0 }];
            const scoreFor = (sourcePosition, targetPosition) => {
              return editor.routeCandidateScore({
                segments,
                labelPoint: { x: 300, y: 300 },
                obstacleRects: [],
                labelObstacleRects: [],
                routedSegments: [],
                routedLabels: [],
                arrowheadPoints: [],
                laneStackBounds: null,
                routeLengthMultiplier: editor.routeLengthMultiplier(
                  { position: sourcePosition },
                  { position: targetPosition }
                ),
                sidePenalty: 0,
              });
            };
            const forwardScore = scoreFor(1, 2);
            const returnScore = scoreFor(2, 1);

            return Number.isFinite(returnScore) &&
              returnScore > 0 &&
              returnScore < forwardScore;
          })();
        JS
      end

      def has_lane_escape_gutter_for_connector_handles?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const verticalLaneStackBounds = { top: 0, bottom: 100 };
            const horizontalLaneStackBounds = { top: 0, bottom: 100, left: 0, right: 100 };
            const insideConnectorGutter = [
              { x1: 0, y1: 108, x2: 100, y2: 108 },
            ];
            const beyondConnectorGutter = [
              { x1: 0, y1: 118, x2: 100, y2: 118 },
            ];
            const insideHorizontalGutter = [
              { x1: 108, y1: 0, x2: 108, y2: 100 },
            ];
            const beyondHorizontalGutter = [
              { x1: 118, y1: 0, x2: 118, y2: 100 },
            ];

            return editor.laneEscapePenalty(insideConnectorGutter, verticalLaneStackBounds) === 0 &&
              editor.laneEscapePenalty(beyondConnectorGutter, verticalLaneStackBounds) > 0 &&
              editor.laneEscapePenalty(insideHorizontalGutter, horizontalLaneStackBounds) === 0 &&
              editor.laneEscapePenalty(beyondHorizontalGutter, horizontalLaneStackBounds) > 0;
          })();
        JS
      end

      def has_label_lane_escape_penalty?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const laneStackBounds = { top: 0, bottom: 100, left: 0, right: 200 };
            const inside = editor.labelLaneEscapePenalty({ x: 100, y: 50 }, laneStackBounds);
            const above = editor.labelLaneEscapePenalty({ x: 100, y: 0 }, laneStackBounds);
            const below = editor.labelLaneEscapePenalty({ x: 100, y: 100 }, laneStackBounds);
            const left = editor.labelLaneEscapePenalty({ x: 0, y: 50 }, laneStackBounds);
            const right = editor.labelLaneEscapePenalty({ x: 200, y: 50 }, laneStackBounds);

            return inside === 0 && above > 0 && below > 0 && left > 0 && right > 0;
          })();
        JS
      end

      def has_lower_escape_route_candidate?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;
            const route = editor.routePoints({
              index: 0,
              source: { x: 500, y: 100 },
              sourceSide: "bottom",
              target: { x: 100, y: 100 },
              targetSide: "bottom",
              obstacleRects: [
                { left: 250, right: 350, top: 0, bottom: 150 },
              ],
              labelObstacleRects: [],
              routedSegments: [],
              routedLabels: [],
              routedArrowheads: [],
              laneStackBounds: { top: 0, bottom: 160 },
              sidePenalty: 0,
            });

            return route.segments.some((segment) => {
              return segment.y1 === segment.y2 && segment.y1 > 160;
            });
          })();
        JS
      end

      def has_global_side_pair_route_scoring?
        has_visual? && page.evaluate_script(<<~JS)
          (() => {
            const editor = document.querySelector(".workflow-visual-editor").workflowVisualEditor;

            editor.routeBetweenHandles = ({ sourceSide, targetSide }) => {
              return {
                source_side: sourceSide,
                target_side: targetSide,
                path: "",
                label_x: 0,
                label_y: 0,
                arrowhead_x: 0,
                arrowhead_y: 0,
                collided: false,
                segments: [],
                score: sourceSide === "bottom" ? 10 : 100,
              };
            };

            const route = editor.edgeRoute({
              allRects: new Map([
                [1, { left: 300, right: 420, top: 100, bottom: 160, centerX: 360, centerY: 130 }],
                [2, { left: 60, right: 180, top: 100, bottom: 160, centerX: 120, centerY: 130 }],
              ]),
              index: 0,
              sourceRect: { left: 300, right: 420, top: 100, bottom: 160, centerX: 360, centerY: 130 },
              targetRect: { left: 60, right: 180, top: 100, bottom: 160, centerX: 120, centerY: 130 },
              sourceStep: { id: 1, position: 2 },
              targetStep: { id: 2, position: 1 },
              usedEndpoints: new Set(),
              routedSegments: [],
              routedLabels: [],
              routedArrowheads: [],
              laneStackBounds: null,
            });

            return route.source_side === "bottom";
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

            if (!verticalSegments.length) {
              return true;
            }

            const longest = verticalSegments.reduce((current, segment) => {
              const currentLength = Math.abs(current.y2 - current.y1);
              const segmentLength = Math.abs(segment.y2 - segment.y1);
              return segmentLength > currentLength ? segment : current;
            }, verticalSegments[0]);
            const startY = Math.min(longest.y1, longest.y2);
            const endY = Math.max(longest.y1, longest.y2);
            const length = endY - startY;
            const candidateRatios = [0.5, 1 / 3, 2 / 3, 0.25, 0.75, 0.2, 0.8, 0.1, 0.9];

            return Math.abs(optionCenter.x - longest.x1) <= 3 &&
              candidateRatios.some((ratio) => Math.abs(optionCenter.y - (startY + length * ratio)) <= 3);
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

      def has_no_option_dropdown_over_step_boxes?
        has_css?(".workflow-visual-editor__option") && page.evaluate_script(<<~JS)
          (() => {
            const overlaps = (rect, otherRect) => {
              return Math.max(rect.left, otherRect.left) < Math.min(rect.right, otherRect.right) &&
                Math.max(rect.top, otherRect.top) < Math.min(rect.bottom, otherRect.bottom);
            };
            const optionRects = Array.from(document.querySelectorAll(".workflow-visual-editor__option")).map((option) => {
              return option.getBoundingClientRect();
            });
            const stepRects = Array.from(document.querySelectorAll(".workflow-visual-editor__step")).map((step) => {
              return step.getBoundingClientRect();
            });

            return optionRects.every((optionRect) => {
              return stepRects.every((stepRect) => !overlaps(optionRect, stepRect));
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

      def drag_existing_connector_target(current_target_step, new_target_step)
        drag(
          connected_handle_selector(current_target_step),
          unconnected_handle_selector(new_target_step),
        )
        self
      end

      def drag_step_to_lane(step, category)
        drag(step_selector(step), lane_selector(category))
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
    end
  end
end
