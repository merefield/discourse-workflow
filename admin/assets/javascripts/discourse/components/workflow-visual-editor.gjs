import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse/lib/decorators";
import CategoryChooser from "discourse/select-kit/components/category-chooser";
import { i18n } from "discourse-i18n";

export default class WorkflowVisualEditor extends Component {
  @service dialog;
  @service router;

  @tracked workflowSteps = [];
  @tracked workflowOptions = [];
  @tracked workflowCategories = [];
  @tracked edgeLayouts = [];
  @tracked previewPath = null;
  @tracked draggedStepId = null;
  @tracked draggedOptionId = null;
  @tracked linkSourceStepId = null;
  @tracked connectorDragMode = null;
  @tracked connectorSourceStepId = null;
  @tracked connectorSourceSide = null;
  @tracked connectorTargetStepId = null;
  @tracked connectorTargetSide = null;
  @tracked newStepName = "";
  @tracked newStepCategoryId = null;
  @tracked isLoading = false;
  boardElement = null;

  get sortedSteps() {
    return [...this.workflowSteps].sort((a, b) => {
      return (a.position || 0) - (b.position || 0);
    });
  }

  get lanes() {
    const lanesById = new Map(
      this.workflowCategories.map((category) => [
        category.id,
        {
          ...category,
          steps: [],
        },
      ])
    );

    for (const step of this.sortedSteps) {
      const category = step.category;
      const categoryId = step.category_id || category?.id;

      if (!categoryId) {
        continue;
      }

      if (lanesById.has(categoryId)) {
        const lane = lanesById.get(categoryId);
        lane.name = category?.name || lane.name;
        lane.color = category?.color || lane.color;
      } else {
        lanesById.set(categoryId, {
          id: categoryId,
          name:
            category?.name ||
            i18n("admin.discourse_workflow.workflows.visual.unknown_category"),
          color: category?.color,
          steps: [],
        });
      }

      lanesById.get(categoryId).steps.push(step);
    }

    return [...lanesById.values()];
  }

  get hasSteps() {
    return this.workflowSteps.length > 0;
  }

  get connectorSides() {
    return ["top", "right", "bottom", "left"];
  }

  get defaultWorkflowOptionId() {
    return this.workflowOptions[0]?.id;
  }

  get workflowEdges() {
    return this.sortedSteps.flatMap((step) => {
      return this.stepOptions(step)
        .filter((stepOption) => {
          return this.workflowSteps.some(
            (targetStep) => targetStep.id === stepOption.target_step_id
          );
        })
        .map((stepOption) => {
          return {
            source_step_id: step.id,
            target_step_id: stepOption.target_step_id,
            step_option: stepOption,
          };
        });
    });
  }

  get positionSlots() {
    return Array.from({ length: this.nextStepPosition }, (_, index) => {
      return index + 1;
    });
  }

  get nextStepPosition() {
    return (
      Math.max(0, ...this.workflowSteps.map((step) => step.position || 0)) + 1
    );
  }

  @bind
  stepOptions(step) {
    return [...(step.workflow_step_options || [])].sort((a, b) => {
      return (a.position || 0) - (b.position || 0);
    });
  }

  @bind
  workflowOptionLabel(workflowOptionId) {
    const workflowOption = this.workflowOptions.find(
      (option) => option.id === workflowOptionId
    );

    if (!workflowOption) {
      return i18n(
        "admin.discourse_workflow.workflows.steps.options.select_an_option"
      );
    }

    return i18n(
      `admin.discourse_workflow.workflows.steps.options.actions.${workflowOption.slug}`
    );
  }

  @bind
  isWorkflowOptionSelected(stepOption, workflowOption) {
    return stepOption.workflow_option_id === workflowOption.id;
  }

  @bind
  stepName(stepId) {
    return this.workflowSteps.find((step) => step.id === stepId)?.name;
  }

  @bind
  stepsForLanePosition(lane, position) {
    return lane.steps.filter((step) => step.position === position);
  }

  @bind
  laneStyle(lane) {
    const color = this.hexColor(lane.color);
    return color ? trustHTML(`border-color: ${color};`) : null;
  }

  @bind
  connectorHandleClass(step, side) {
    const classes = [
      "workflow-visual-editor__connector-handle",
      `workflow-visual-editor__connector-handle--${side}`,
    ];

    if (this.edgeForHandle(step, side)) {
      classes.push("workflow-visual-editor__connector-handle--connected");
    }

    return classes.join(" ");
  }

  @bind
  connectorHandleLabel(step, side) {
    return i18n("admin.discourse_workflow.workflows.visual.connector_handle", {
      step: step.name,
      side,
    });
  }

  edgeForHandle(step, side) {
    return this.edgeLayouts.find((edge) => {
      return (
        (edge.source_step_id === step.id && edge.source_side === side) ||
        (edge.target_step_id === step.id && edge.target_side === side)
      );
    });
  }

  edgeForTargetHandle(step, side) {
    return this.edgeLayouts.find((edge) => {
      return edge.target_step_id === step.id && edge.target_side === side;
    });
  }

  edgeForSourceHandle(step, side) {
    return this.edgeLayouts.find((edge) => {
      return edge.source_step_id === step.id && edge.source_side === side;
    });
  }

  mergeWorkflowCategories(workflowSteps, allCategories = []) {
    const categoriesById = new Map(
      this.workflowCategories.map((category) => [category.id, category])
    );
    const allCategoriesById = new Map(
      allCategories.map((category) => [category.id, category])
    );
    const workflowParentCategoryIds = new Set();

    for (const step of workflowSteps) {
      const category = step.category || allCategoriesById.get(step.category_id);
      const categoryId = step.category_id || category?.id;

      if (!categoryId) {
        continue;
      }

      if (category?.parent_category_id) {
        workflowParentCategoryIds.add(category.parent_category_id);
      } else {
        workflowParentCategoryIds.add(categoryId);
      }

      categoriesById.set(categoryId, {
        id: categoryId,
        name:
          category?.name ||
          categoriesById.get(categoryId)?.name ||
          i18n("admin.discourse_workflow.workflows.visual.unknown_category"),
        color: category?.color || categoriesById.get(categoryId)?.color,
      });
    }

    for (const category of allCategories) {
      if (workflowParentCategoryIds.has(category.parent_category_id)) {
        categoriesById.set(category.id, {
          id: category.id,
          name: category.name,
          color: category.color,
          parent_category_id: category.parent_category_id,
        });
      }
    }

    this.workflowCategories = [...categoriesById.values()];
  }

  updateStep(step, attributes) {
    return ajax(
      `/admin/plugins/discourse-workflow/workflow_steps/${step.id}.json`,
      {
        type: "PUT",
        data: {
          workflow_step: {
            workflow_id: step.workflow_id,
            position: step.position,
            name: step.name,
            description: step.description,
            category_id: step.category_id,
            overdue_days: step.overdue_days,
            ai_enabled: step.ai_enabled,
            ai_prompt: step.ai_prompt,
            ...attributes,
          },
        },
      }
    );
  }

  @action
  confirmDeleteStep(step) {
    if (this.args.disabled) {
      return;
    }

    return this.dialog.confirm({
      message: i18n(
        "admin.discourse_workflow.workflows.visual.confirm_delete_step"
      ),
      confirmButtonClass: "btn-danger",
      confirmButtonLabel:
        "admin.discourse_workflow.workflows.visual.delete_step",
      didConfirm: async () => {
        try {
          await ajax(
            `/admin/plugins/discourse-workflow/workflow_steps/${step.id}.json`,
            { type: "DELETE" }
          );
          await this.reloadGraphInPlace();
        } catch (err) {
          popupAjaxError(err);
        }
      },
    });
  }

  updateStepOption(stepOption, attributes) {
    return ajax(
      `/admin/plugins/discourse-workflow/workflow_step_options/${stepOption.id}.json`,
      {
        type: "PUT",
        data: {
          workflow_step_option: {
            position: stepOption.position,
            workflow_step_id: stepOption.workflow_step_id,
            workflow_option_id: stepOption.workflow_option_id,
            target_step_id: stepOption.target_step_id,
            ...attributes,
          },
        },
      }
    );
  }

  @action
  confirmDeleteStepOption(stepOption) {
    if (this.args.disabled) {
      return;
    }

    return this.dialog.confirm({
      message: i18n(
        "admin.discourse_workflow.workflows.visual.confirm_delete_connector"
      ),
      confirmButtonClass: "btn-danger",
      confirmButtonLabel:
        "admin.discourse_workflow.workflows.visual.delete_connector",
      didConfirm: async () => {
        try {
          await ajax(
            `/admin/plugins/discourse-workflow/workflow_step_options/${stepOption.id}.json`,
            { type: "DELETE" }
          );
          await this.reloadGraphInPlace();
        } catch (err) {
          popupAjaxError(err);
        }
      },
    });
  }

  @action
  registerTestInterface(element) {
    element.workflowVisualEditor = this;
  }

  @action
  async loadGraph() {
    if (!this.args.workflow?.id) {
      return;
    }

    this.isLoading = true;

    try {
      const [workflowStepsResult, workflowOptionsResult] = await Promise.all([
        ajax(
          `/admin/plugins/discourse-workflow/workflows/${this.args.workflow.id}/workflow_steps.json`
        ),
        ajax("/admin/plugins/discourse-workflow/workflow_options.json"),
      ]);

      this.workflowSteps = workflowStepsResult.workflow_steps || [];
      this.workflowOptions = workflowOptionsResult.workflow_options || [];
      this.mergeWorkflowCategories(
        this.workflowSteps,
        workflowStepsResult.workflow_categories || []
      );
      this.scheduleEdgeLayout();
    } catch (err) {
      popupAjaxError(err);
    } finally {
      this.isLoading = false;
    }
  }

  captureScrollPosition() {
    if (typeof window === "undefined") {
      return null;
    }

    return {
      x: window.scrollX,
      y: window.scrollY,
    };
  }

  restoreScrollPosition(scrollPosition) {
    if (!scrollPosition || typeof window === "undefined") {
      return;
    }

    requestAnimationFrame(() => {
      window.scrollTo(scrollPosition.x, scrollPosition.y);
      requestAnimationFrame(() => {
        window.scrollTo(scrollPosition.x, scrollPosition.y);
      });
    });
  }

  async reloadGraphInPlace() {
    const scrollPosition = this.captureScrollPosition();

    await this.loadGraph();
    this.restoreScrollPosition(scrollPosition);
  }

  @action
  captureBoard(element) {
    this.boardElement = element;
    this.scheduleEdgeLayout();
  }

  @action
  scheduleEdgeLayout() {
    requestAnimationFrame(() => this.updateEdgeLayouts());
  }

  laneStackBounds(boardRect) {
    const laneElements = this.boardElement.querySelectorAll(
      ".workflow-visual-editor__lane"
    );

    if (!laneElements.length) {
      return null;
    }

    const bounds = Array.from(laneElements).map((lane) => {
      const rect = lane.getBoundingClientRect();
      const headerRect = lane
        .querySelector(".workflow-visual-editor__lane-header")
        ?.getBoundingClientRect();
      const contentRect = lane
        .querySelector(".workflow-visual-editor__lane-steps")
        ?.getBoundingClientRect();

      return {
        left: rect.left - boardRect.left,
        right: rect.right - boardRect.left,
        top: rect.top - boardRect.top,
        bottom: rect.bottom - boardRect.top,
        contentLeft: (contentRect || rect).left - boardRect.left,
        contentRight: (contentRect || rect).right - boardRect.left,
        labelTop: (headerRect || rect).top - boardRect.top,
        labelBottom: (headerRect || rect).bottom - boardRect.top,
      };
    });

    return {
      left: Math.min(...bounds.map((bound) => bound.left)),
      right: Math.max(...bounds.map((bound) => bound.right)),
      top: Math.min(...bounds.map((bound) => bound.top)),
      bottom: Math.max(...bounds.map((bound) => bound.bottom)),
      lanes: bounds,
    };
  }

  updateEdgeLayouts() {
    if (!this.boardElement) {
      return;
    }

    const boardRect = this.boardElement.getBoundingClientRect();
    const stepRectById = new Map();
    const laneStackBounds = this.laneStackBounds(boardRect);

    for (const step of this.workflowSteps) {
      const element = this.boardElement.querySelector(
        `[data-workflow-step-id="${step.id}"]`
      );

      if (!element) {
        continue;
      }

      const rect = element.getBoundingClientRect();
      stepRectById.set(step.id, {
        left: rect.left - boardRect.left,
        right: rect.right - boardRect.left,
        top: rect.top - boardRect.top,
        bottom: rect.bottom - boardRect.top,
        width: rect.width,
        height: rect.height,
        centerX: rect.left - boardRect.left + rect.width / 2,
        centerY: rect.top - boardRect.top + rect.height / 2,
      });
    }

    const usedEndpoints = new Set();
    const routedSegments = [];
    const routedLabels = [];
    const routedArrowheads = [];

    this.edgeLayouts = this.workflowEdges
      .map((edge, index) => {
        const sourceRect = stepRectById.get(edge.source_step_id);
        const targetRect = stepRectById.get(edge.target_step_id);
        const sourceStep = this.workflowSteps.find(
          (step) => step.id === edge.source_step_id
        );
        const targetStep = this.workflowSteps.find(
          (step) => step.id === edge.target_step_id
        );

        if (!sourceRect || !targetRect || !sourceStep || !targetStep) {
          return null;
        }

        const route = this.edgeRoute({
          allRects: stepRectById,
          index,
          sourceRect,
          targetRect,
          sourceStep,
          targetStep,
          usedEndpoints,
          routedSegments,
          routedLabels,
          routedArrowheads,
          laneStackBounds,
        });

        usedEndpoints.add(
          this.endpointKey(edge.source_step_id, route.source_side)
        );
        usedEndpoints.add(
          this.endpointKey(edge.target_step_id, route.target_side)
        );
        routedSegments.push(...route.segments);
        routedLabels.push({ x: route.label_x, y: route.label_y });
        routedArrowheads.push({ x: route.arrowhead_x, y: route.arrowhead_y });

        return {
          ...edge,
          path: route.path,
          label_x: route.label_x,
          label_y: route.label_y,
          source_side: route.source_side,
          target_side: route.target_side,
        };
      })
      .filter(Boolean);
  }

  edgeRoute({
    allRects,
    index,
    sourceRect,
    targetRect,
    sourceStep,
    targetStep,
    usedEndpoints,
    routedSegments,
    routedLabels,
    routedArrowheads,
    laneStackBounds,
  }) {
    const obstacleRects = this.obstacleRects(
      allRects,
      sourceStep.id,
      targetStep.id
    );
    const labelObstacleRects = [...allRects.values()];
    const routes = [];

    for (const [sourceSide, targetSide] of this.edgeSidePairs(
      sourceStep,
      targetStep
    )) {
      if (
        usedEndpoints.has(this.endpointKey(sourceStep.id, sourceSide)) ||
        usedEndpoints.has(this.endpointKey(targetStep.id, targetSide))
      ) {
        continue;
      }

      const route = this.routeBetweenHandles({
        index,
        sourceRect,
        sourceSide,
        targetRect,
        targetSide,
        obstacleRects,
        endpointObstacleRects: [sourceRect, targetRect],
        labelObstacleRects,
        routedSegments,
        routedLabels,
        routedArrowheads,
        laneStackBounds,
        routeLengthMultiplier: this.routeLengthMultiplier(
          sourceStep,
          targetStep
        ),
        allowLaneHeaderRouting:
          (targetStep.position || 0) < (sourceStep.position || 0),
        sidePenalty: this.edgeSidePairPenalty(
          sourceStep,
          targetStep,
          sourceSide
        ),
      });

      routes.push(route);
    }

    const viableRoutes = routes
      .filter((route) => !route.collided && route.score !== Infinity)
      .sort((a, b) => a.score - b.score);

    if (viableRoutes.length) {
      return viableRoutes[0];
    }

    const fallbackRoutes = routes
      .filter((route) => route.score !== Infinity)
      .sort((a, b) => a.score - b.score);

    return (
      fallbackRoutes[0] ||
      routes[0] ||
      this.defaultEdgeRoute({
        index,
        sourceRect,
        targetRect,
        obstacleRects,
        labelObstacleRects,
        routedSegments,
        routedLabels,
        routedArrowheads,
        laneStackBounds,
      })
    );
  }

  defaultEdgeRoute({
    index,
    sourceRect,
    targetRect,
    obstacleRects,
    labelObstacleRects,
    routedSegments,
    routedLabels,
    routedArrowheads,
    laneStackBounds,
  }) {
    return this.routeBetweenHandles({
      index,
      sourceRect,
      sourceSide: "right",
      targetRect,
      targetSide: "left",
      obstacleRects,
      endpointObstacleRects: [sourceRect, targetRect],
      labelObstacleRects,
      routedSegments,
      routedLabels,
      routedArrowheads,
      laneStackBounds,
      sidePenalty: 0,
    });
  }

  edgeSidePairs(sourceStep, targetStep) {
    const sourcePosition = sourceStep.position || 0;
    const targetPosition = targetStep.position || 0;

    if (targetPosition > sourcePosition) {
      return this.allSidePairs(
        ["right", "bottom", "top", "left"],
        ["left", "top", "bottom", "right"]
      );
    }

    if (targetPosition < sourcePosition) {
      return this.allSidePairs(
        ["top", "left", "bottom", "right"],
        ["top", "right", "bottom", "left"]
      );
    }

    return this.allSidePairs(
      ["bottom", "top", "right", "left"],
      ["top", "bottom", "left", "right"]
    );
  }

  allSidePairs(sourceSides, targetSides) {
    return sourceSides.flatMap((sourceSide) => {
      return targetSides.map((targetSide) => [sourceSide, targetSide]);
    });
  }

  edgeSidePairPenalty(sourceStep, targetStep, sourceSide) {
    if ((targetStep.position || 0) <= (sourceStep.position || 0)) {
      return 0;
    }

    if (sourceSide === "right") {
      return 0;
    }

    if (sourceSide === "bottom" || sourceSide === "top") {
      return 350;
    }

    return 1200;
  }

  routeLengthMultiplier(sourceStep, targetStep) {
    if ((targetStep.position || 0) < (sourceStep.position || 0)) {
      return 0.15;
    }

    return 1;
  }

  routeBetweenHandles({
    index,
    sourceRect,
    sourceSide,
    targetRect,
    targetSide,
    obstacleRects,
    endpointObstacleRects = [],
    labelObstacleRects = obstacleRects,
    routedSegments = [],
    routedLabels = [],
    routedArrowheads = [],
    laneStackBounds = null,
    routeLengthMultiplier = 1,
    allowLaneHeaderRouting = false,
    sidePenalty = 0,
  }) {
    const source = this.connectorPoint(sourceRect, sourceSide);
    const target = this.connectorPoint(targetRect, targetSide);
    const route = this.routePoints({
      index,
      source,
      sourceSide,
      target,
      targetSide,
      obstacleRects,
      endpointObstacleRects,
      labelObstacleRects,
      routedSegments,
      routedLabels,
      routedArrowheads,
      laneStackBounds,
      routeLengthMultiplier,
      allowLaneHeaderRouting,
      sidePenalty,
    });

    return {
      ...route,
      source_side: sourceSide,
      target_side: targetSide,
    };
  }

  routePoints({
    index,
    source,
    sourceSide,
    target,
    targetSide,
    obstacleRects,
    endpointObstacleRects = [],
    labelObstacleRects = obstacleRects,
    routedSegments = [],
    routedLabels = [],
    routedArrowheads = [],
    laneStackBounds = null,
    routeLengthMultiplier = 1,
    allowLaneHeaderRouting = false,
    sidePenalty = 0,
  }) {
    const escapeDistance = 26 + this.routeOffset(index, 8);
    const sourceEscape = this.offsetPoint(source, sourceSide, escapeDistance);
    const targetEscape = targetSide
      ? this.offsetPoint(target, targetSide, escapeDistance)
      : target;
    const baseMidX = (sourceEscape.x + targetEscape.x) / 2;
    const baseMidY = (sourceEscape.y + targetEscape.y) / 2;
    const outsideX =
      Math.max(source.x, target.x, sourceEscape.x, targetEscape.x) +
      64 +
      index * 18;
    const outsideY =
      Math.min(source.y, target.y, sourceEscape.y, targetEscape.y) -
      40 -
      index * 18;
    const outsideBottomY =
      Math.max(source.y, target.y, sourceEscape.y, targetEscape.y) +
      40 +
      index * 18;
    const candidates = [
      ...this.routingCandidates(baseMidX, 48).map((midX) => ({
        points: this.compactPoints([
          source,
          sourceEscape,
          { x: midX, y: sourceEscape.y },
          { x: midX, y: targetEscape.y },
          targetEscape,
          target,
        ]),
        penalty: 0,
      })),
      ...this.routingCandidates(baseMidY, 36).map((midY) => ({
        points: this.compactPoints([
          source,
          sourceEscape,
          { x: sourceEscape.x, y: midY },
          { x: targetEscape.x, y: midY },
          targetEscape,
          target,
        ]),
        penalty: 0,
      })),
      ...(allowLaneHeaderRouting
        ? this.laneHeaderRoutingCandidates(
            laneStackBounds,
            sourceEscape,
            targetEscape
          ).map((midY) => ({
            points: this.headerRoutePoints({
              source,
              sourceSide,
              sourceEscape,
              target,
              targetSide,
              targetEscape,
              midY,
              index,
            }),
            penalty: 0,
          }))
        : []),
      {
        points: this.compactPoints([
          source,
          sourceEscape,
          { x: outsideX, y: sourceEscape.y },
          { x: outsideX, y: targetEscape.y },
          targetEscape,
          target,
        ]),
        penalty: 0,
      },
      {
        points: this.compactPoints([
          source,
          sourceEscape,
          { x: sourceEscape.x, y: outsideY },
          { x: targetEscape.x, y: outsideY },
          targetEscape,
          target,
        ]),
        penalty: 0,
      },
      {
        points: this.compactPoints([
          source,
          sourceEscape,
          { x: sourceEscape.x, y: outsideBottomY },
          { x: targetEscape.x, y: outsideBottomY },
          targetEscape,
          target,
        ]),
        penalty: 0,
      },
    ];
    const scoredCandidates = candidates
      .flatMap((candidate) => {
        const points = candidate.points;
        const segments = this.pointsToSegments(points);

        return this.labelCandidatesForSegments(segments, laneStackBounds).map(
          (labelCandidate) => ({
            points,
            segments,
            labelPoint: labelCandidate.point,
            score:
              this.routeCandidateScore({
                segments,
                labelPoint: labelCandidate.point,
                obstacleRects,
                endpointObstacleRects,
                labelObstacleRects,
                routedSegments,
                routedLabels,
                arrowheadPoints: [...routedArrowheads, target],
                laneStackBounds,
                routeLengthMultiplier,
                sidePenalty,
              }) +
              labelCandidate.penalty +
              candidate.penalty,
          })
        );
      })
      .filter((candidate) => candidate.score !== Infinity)
      .sort((a, b) => a.score - b.score);
    const selectedCandidate = scoredCandidates[0] || {
      points: candidates[0].points,
      segments: this.pointsToSegments(candidates[0].points),
      labelPoint: this.labelCandidatesForSegments(
        this.pointsToSegments(candidates[0].points),
        laneStackBounds
      )[0].point,
      score: Infinity,
    };

    return {
      path: this.pointsToPath(selectedCandidate.points),
      label_x: selectedCandidate.labelPoint.x,
      label_y: selectedCandidate.labelPoint.y,
      arrowhead_x: target.x,
      arrowhead_y: target.y,
      collided: this.pathCollides(selectedCandidate.segments, obstacleRects),
      segments: selectedCandidate.segments,
      score: selectedCandidate.score,
    };
  }

  connectorPoint(rect, side) {
    if (side === "top") {
      return { x: rect.centerX, y: rect.top };
    }

    if (side === "right") {
      return { x: rect.right, y: rect.centerY };
    }

    if (side === "bottom") {
      return { x: rect.centerX, y: rect.bottom };
    }

    return { x: rect.left, y: rect.centerY };
  }

  offsetPoint(point, side, distance) {
    if (!side) {
      return point;
    }

    if (side === "top") {
      return { x: point.x, y: point.y - distance };
    }

    if (side === "right") {
      return { x: point.x + distance, y: point.y };
    }

    if (side === "bottom") {
      return { x: point.x, y: point.y + distance };
    }

    return { x: point.x - distance, y: point.y };
  }

  pointsToSegments(points) {
    return points.slice(1).map((point, index) => {
      const previous = points[index];

      return {
        x1: previous.x,
        y1: previous.y,
        x2: point.x,
        y2: point.y,
      };
    });
  }

  routeCandidateScore({
    segments,
    labelPoint,
    obstacleRects,
    endpointObstacleRects = [],
    labelObstacleRects,
    routedSegments,
    routedLabels,
    arrowheadPoints = [],
    laneStackBounds,
    routeLengthMultiplier = 1,
    sidePenalty,
  }) {
    if (this.routeDoublesBack(segments)) {
      return Infinity;
    }

    if (this.pathCollides(segments, obstacleRects)) {
      return Infinity;
    }

    if (
      this.pathCollides(
        this.nonEndpointSegments(segments),
        endpointObstacleRects,
        0
      )
    ) {
      return Infinity;
    }

    const overlapCount = this.segmentOverlapCount(segments, routedSegments);

    if (overlapCount > 0) {
      return Infinity;
    }

    return (
      this.routeLength(segments) * routeLengthMultiplier +
      this.shortSegmentPenalty(segments) +
      this.routeTurnCount(segments) * 90 +
      this.segmentCrossingCount(segments, routedSegments) * 2000 +
      this.horizontalSegmentLabelPenalty(segments, routedLabels) +
      this.laneHeaderTravelPenalty(segments, laneStackBounds) +
      this.labelPenalty({
        labelPoint,
        routedLabels,
        labelObstacleRects,
        arrowheadPoints,
        routedSegments,
        laneStackBounds,
      }) +
      this.laneBorderTravelPenalty(segments, laneStackBounds) +
      this.laneGapTravelPenalty(segments, laneStackBounds) +
      this.laneEscapePenalty(segments, laneStackBounds) +
      sidePenalty
    );
  }

  labelPenalty({
    labelPoint,
    routedLabels,
    labelObstacleRects,
    arrowheadPoints,
    routedSegments,
    laneStackBounds,
  }) {
    return (
      this.labelCollisionPenalty(labelPoint, routedLabels) +
      this.labelObstaclePenalty(labelPoint, labelObstacleRects) +
      this.labelArrowheadPenalty(labelPoint, arrowheadPoints) +
      this.labelSegmentPenalty(labelPoint, routedSegments) +
      this.labelLaneBoundaryPenalty(labelPoint, laneStackBounds)
    );
  }

  laneBorderTravelPenalty(segments, laneStackBounds) {
    if (!laneStackBounds?.lanes?.length) {
      return 0;
    }

    return segments.reduce((penalty, segment) => {
      if (segment.y1 !== segment.y2) {
        return penalty;
      }

      const segmentLeft = Math.min(segment.x1, segment.x2);
      const segmentRight = Math.max(segment.x1, segment.x2);

      return (
        penalty +
        laneStackBounds.lanes.reduce((lanePenalty, lane) => {
          const travelsAlongLaneEdge =
            Math.abs(segment.y1 - lane.top) <= 2 ||
            Math.abs(segment.y1 - lane.bottom) <= 2;

          if (!travelsAlongLaneEdge) {
            return lanePenalty;
          }

          const laneLeft = lane.contentLeft ?? lane.left;
          const laneRight = lane.contentRight ?? lane.right;
          const overlap =
            Math.min(segmentRight, laneRight) - Math.max(segmentLeft, laneLeft);

          return overlap > 0 ? lanePenalty + overlap * 80 : lanePenalty;
        }, 0)
      );
    }, 0);
  }

  laneGapTravelPenalty(segments, laneStackBounds) {
    if (!laneStackBounds?.lanes?.length) {
      return 0;
    }

    const lanes = [...laneStackBounds.lanes].sort((a, b) => a.top - b.top);

    return segments.reduce((penalty, segment) => {
      if (segment.y1 !== segment.y2) {
        return penalty;
      }

      const segmentLeft = Math.min(segment.x1, segment.x2);
      const segmentRight = Math.max(segment.x1, segment.x2);

      return (
        penalty +
        lanes.slice(1).reduce((gapPenalty, lane, index) => {
          const previousLane = lanes[index];
          const gapTop = previousLane.bottom;
          const gapBottom = lane.top;

          if (segment.y1 <= gapTop || segment.y1 >= gapBottom) {
            return gapPenalty;
          }

          const previousLaneLeft =
            previousLane.contentLeft ?? previousLane.left;
          const previousLaneRight =
            previousLane.contentRight ?? previousLane.right;
          const laneLeft = lane.contentLeft ?? lane.left;
          const laneRight = lane.contentRight ?? lane.right;
          const overlap =
            Math.min(segmentRight, previousLaneRight, laneRight) -
            Math.max(segmentLeft, previousLaneLeft, laneLeft);

          return overlap > 0 ? gapPenalty + overlap * 140 : gapPenalty;
        }, 0)
      );
    }, 0);
  }

  laneHeaderTravelPenalty(segments, laneStackBounds) {
    if (!laneStackBounds?.lanes?.length) {
      return 0;
    }

    return segments.reduce((penalty, segment) => {
      if (segment.y1 !== segment.y2) {
        return penalty;
      }

      const segmentLeft = Math.min(segment.x1, segment.x2);
      const segmentRight = Math.max(segment.x1, segment.x2);

      return (
        penalty +
        laneStackBounds.lanes.reduce((lanePenalty, lane) => {
          if (
            !Number.isFinite(lane.labelTop) ||
            !Number.isFinite(lane.labelBottom) ||
            segment.y1 < lane.labelTop ||
            segment.y1 > lane.labelBottom
          ) {
            return lanePenalty;
          }

          const laneLeft = lane.contentLeft ?? lane.left;
          const laneRight = lane.contentRight ?? lane.right;
          const overlap =
            Math.min(segmentRight, laneRight) - Math.max(segmentLeft, laneLeft);

          return overlap > 0 ? lanePenalty + overlap * 45 : lanePenalty;
        }, 0)
      );
    }, 0);
  }

  laneEscapePenalty(segments, laneStackBounds) {
    if (!laneStackBounds) {
      return 0;
    }

    const connectorGutter = 12;
    const upperLimit = laneStackBounds.top - connectorGutter;
    const lowerLimit = laneStackBounds.bottom + connectorGutter;
    const hasHorizontalLimits =
      Number.isFinite(laneStackBounds.left) &&
      Number.isFinite(laneStackBounds.right);
    const leftLimit = hasHorizontalLimits
      ? laneStackBounds.left - connectorGutter
      : null;
    const rightLimit = hasHorizontalLimits
      ? laneStackBounds.right + connectorGutter
      : null;

    return segments.reduce((penalty, segment) => {
      const escapedAbove =
        Math.max(0, upperLimit - segment.y1) +
        Math.max(0, upperLimit - segment.y2);
      const escapedBelow =
        Math.max(0, segment.y1 - lowerLimit) +
        Math.max(0, segment.y2 - lowerLimit);
      const escapedLeft = hasHorizontalLimits
        ? Math.max(0, leftLimit - segment.x1) +
          Math.max(0, leftLimit - segment.x2)
        : 0;
      const escapedRight = hasHorizontalLimits
        ? Math.max(0, segment.x1 - rightLimit) +
          Math.max(0, segment.x2 - rightLimit)
        : 0;

      return (
        penalty +
        (escapedAbove + escapedBelow + escapedLeft + escapedRight) * 2880
      );
    }, 0);
  }

  optionLabelRect(labelPoint) {
    const halfWidth = 80;

    return {
      left: labelPoint.x - halfWidth,
      right: labelPoint.x + halfWidth,
      top: labelPoint.y - 20,
      bottom: labelPoint.y + 20,
    };
  }

  labelLaneEscapePenalty(labelPoint, laneStackBounds) {
    if (!laneStackBounds) {
      return 0;
    }

    const labelRect = this.optionLabelRect(labelPoint);
    const escapedAbove = Math.max(0, laneStackBounds.top - labelRect.top);
    const escapedBelow = Math.max(0, labelRect.bottom - laneStackBounds.bottom);
    const lanes = laneStackBounds.lanes || [];
    const leftLimit =
      laneStackBounds.left ??
      (lanes.length ? Math.min(...lanes.map((lane) => lane.left)) : null);
    const rightLimit =
      laneStackBounds.right ??
      (lanes.length ? Math.max(...lanes.map((lane) => lane.right)) : null);
    const escapedLeft = Number.isFinite(leftLimit)
      ? Math.max(0, leftLimit - labelRect.left)
      : 0;
    const escapedRight = Number.isFinite(rightLimit)
      ? Math.max(0, labelRect.right - rightLimit)
      : 0;

    return escapedAbove + escapedBelow + escapedLeft + escapedRight > 0
      ? Infinity
      : 0;
  }

  labelCollisionPenalty(labelPoint, routedLabels) {
    return routedLabels.reduce((penalty, routedLabel) => {
      const horizontalDistance = Math.abs(labelPoint.x - routedLabel.x);
      const verticalDistance = Math.abs(labelPoint.y - routedLabel.y);
      const likelyHorizontalOverlap = horizontalDistance < 160;

      if (likelyHorizontalOverlap && verticalDistance < 40) {
        return Infinity;
      }

      return penalty;
    }, 0);
  }

  labelObstaclePenalty(labelPoint, obstacleRects) {
    const labelRect = this.optionLabelRect(labelPoint);

    return obstacleRects.reduce((penalty, rect) => {
      const overlaps =
        Math.max(labelRect.left, rect.left) <
          Math.min(labelRect.right, rect.right) &&
        Math.max(labelRect.top, rect.top) <
          Math.min(labelRect.bottom, rect.bottom);

      return overlaps ? Infinity : penalty;
    }, 0);
  }

  labelArrowheadPenalty(labelPoint, arrowheadPoints) {
    const labelRect = this.optionLabelRect(labelPoint);

    return arrowheadPoints.reduce((penalty, arrowheadPoint) => {
      const covered =
        arrowheadPoint.x >= labelRect.left &&
        arrowheadPoint.x <= labelRect.right &&
        arrowheadPoint.y >= labelRect.top &&
        arrowheadPoint.y <= labelRect.bottom;

      return covered ? Infinity : penalty;
    }, 0);
  }

  labelSegmentPenalty(labelPoint, routedSegments) {
    const labelRect = this.optionLabelRect(labelPoint);

    return routedSegments.reduce((penalty, segment) => {
      const segmentIntersectsLabel =
        this.horizontalSegmentIntersectsRect(segment, labelRect) ||
        this.verticalSegmentIntersectsRect(segment, labelRect);

      return segmentIntersectsLabel && segment.y1 === segment.y2
        ? Infinity
        : penalty;
    }, 0);
  }

  labelLaneBoundaryPenalty(labelPoint, laneStackBounds) {
    if (!laneStackBounds?.lanes?.length) {
      return 0;
    }

    const labelRect = this.optionLabelRect(labelPoint);

    return laneStackBounds.lanes.reduce((penalty, lane) => {
      const overlapsTop =
        labelRect.top <= lane.top &&
        labelRect.bottom >= lane.top &&
        labelRect.right >= lane.left &&
        labelRect.left <= lane.right;
      const overlapsBottom =
        labelRect.top <= lane.bottom &&
        labelRect.bottom >= lane.bottom &&
        labelRect.right >= lane.left &&
        labelRect.left <= lane.right;
      const overlapsLaneLabel =
        labelRect.top <= lane.labelBottom &&
        labelRect.bottom >= lane.labelTop &&
        labelRect.right >= lane.left &&
        labelRect.left <= lane.right;

      return overlapsTop || overlapsBottom || overlapsLaneLabel
        ? Infinity
        : penalty;
    }, 0);
  }

  horizontalSegmentLabelPenalty(segments, routedLabels) {
    return segments.reduce((penalty, segment) => {
      if (segment.y1 !== segment.y2) {
        return penalty;
      }

      return (
        penalty +
        routedLabels.reduce((labelPenalty, routedLabel) => {
          const labelRect = this.optionLabelRect(routedLabel);

          return this.horizontalSegmentIntersectsRect(segment, labelRect)
            ? Infinity
            : labelPenalty;
        }, 0)
      );
    }, 0);
  }

  horizontalSegmentIntersectsRect(segment, rect) {
    if (segment.y1 !== segment.y2) {
      return false;
    }

    const segmentLeft = Math.min(segment.x1, segment.x2);
    const segmentRight = Math.max(segment.x1, segment.x2);

    return (
      segment.y1 >= rect.top &&
      segment.y1 <= rect.bottom &&
      Math.min(segmentRight, rect.right) > Math.max(segmentLeft, rect.left)
    );
  }

  verticalSegmentIntersectsRect(segment, rect) {
    if (segment.x1 !== segment.x2) {
      return false;
    }

    const segmentTop = Math.min(segment.y1, segment.y2);
    const segmentBottom = Math.max(segment.y1, segment.y2);

    return (
      segment.x1 >= rect.left &&
      segment.x1 <= rect.right &&
      Math.min(segmentBottom, rect.bottom) > Math.max(segmentTop, rect.top)
    );
  }

  routeDoublesBack(segments) {
    return segments.slice(1).some((segment, index) => {
      const previous = segments[index];
      const bothHorizontal =
        previous.y1 === previous.y2 && segment.y1 === segment.y2;
      const bothVertical =
        previous.x1 === previous.x2 && segment.x1 === segment.x2;

      if (bothHorizontal && previous.y1 === segment.y1) {
        return (
          Math.sign(previous.x2 - previous.x1) !==
          Math.sign(segment.x2 - segment.x1)
        );
      }

      if (bothVertical && previous.x1 === segment.x1) {
        return (
          Math.sign(previous.y2 - previous.y1) !==
          Math.sign(segment.y2 - segment.y1)
        );
      }

      return false;
    });
  }

  routeLength(segments) {
    return segments.reduce((total, segment) => {
      return (
        total +
        Math.abs(segment.x2 - segment.x1) +
        Math.abs(segment.y2 - segment.y1)
      );
    }, 0);
  }

  shortSegmentPenalty(segments) {
    const minimumSegmentLength = 24;

    return segments.reduce((penalty, segment) => {
      const segmentLength =
        Math.abs(segment.x2 - segment.x1) + Math.abs(segment.y2 - segment.y1);

      if (segmentLength >= minimumSegmentLength) {
        return penalty;
      }

      return penalty + (minimumSegmentLength - segmentLength) * 12;
    }, 0);
  }

  routeTurnCount(segments) {
    return segments.slice(1).filter((segment, index) => {
      const previous = segments[index];
      const previousHorizontal = previous.y1 === previous.y2;
      const currentHorizontal = segment.y1 === segment.y2;

      return previousHorizontal !== currentHorizontal;
    }).length;
  }

  segmentOverlapCount(segments, routedSegments) {
    return segments.reduce((count, segment) => {
      return (
        count +
        routedSegments.filter((routedSegment) => {
          return this.segmentsOverlap(segment, routedSegment);
        }).length
      );
    }, 0);
  }

  segmentCrossingCount(segments, routedSegments) {
    return segments.reduce((count, segment) => {
      return (
        count +
        routedSegments.filter((routedSegment) => {
          return this.segmentsCross(segment, routedSegment);
        }).length
      );
    }, 0);
  }

  segmentsOverlap(segment, otherSegment) {
    if (segment.y1 === segment.y2 && otherSegment.y1 === otherSegment.y2) {
      return (
        segment.y1 === otherSegment.y1 &&
        this.rangesOverlap(
          segment.x1,
          segment.x2,
          otherSegment.x1,
          otherSegment.x2
        )
      );
    }

    if (segment.x1 === segment.x2 && otherSegment.x1 === otherSegment.x2) {
      return (
        segment.x1 === otherSegment.x1 &&
        this.rangesOverlap(
          segment.y1,
          segment.y2,
          otherSegment.y1,
          otherSegment.y2
        )
      );
    }

    return false;
  }

  segmentsCross(segment, otherSegment) {
    if (this.segmentsOverlap(segment, otherSegment)) {
      return false;
    }

    const segmentHorizontal = segment.y1 === segment.y2;
    const otherHorizontal = otherSegment.y1 === otherSegment.y2;

    if (segmentHorizontal === otherHorizontal) {
      return false;
    }

    const horizontal = segmentHorizontal ? segment : otherSegment;
    const vertical = segmentHorizontal ? otherSegment : segment;

    return (
      this.valueBetween(vertical.x1, horizontal.x1, horizontal.x2) &&
      this.valueBetween(horizontal.y1, vertical.y1, vertical.y2)
    );
  }

  rangesOverlap(start, end, otherStart, otherEnd) {
    const min = Math.min(start, end);
    const max = Math.max(start, end);
    const otherMin = Math.min(otherStart, otherEnd);
    const otherMax = Math.max(otherStart, otherEnd);

    return Math.max(min, otherMin) < Math.min(max, otherMax);
  }

  valueBetween(value, start, end) {
    return value > Math.min(start, end) && value < Math.max(start, end);
  }

  laneHeaderRoutingCandidates(laneStackBounds, sourceEscape, targetEscape) {
    if (!laneStackBounds?.lanes?.length) {
      return [];
    }

    const routeTop = Math.min(sourceEscape.y, targetEscape.y);
    const routeBottom = Math.max(sourceEscape.y, targetEscape.y);

    return laneStackBounds.lanes
      .map((lane) => {
        if (
          !Number.isFinite(lane.labelTop) ||
          !Number.isFinite(lane.labelBottom)
        ) {
          return null;
        }

        const labelCenter = (lane.labelTop + lane.labelBottom) / 2;
        return labelCenter >= routeTop && labelCenter <= routeBottom
          ? labelCenter
          : null;
      })
      .filter((candidate) => candidate !== null);
  }

  headerRoutePoints({
    source,
    sourceSide,
    sourceEscape,
    target,
    targetSide,
    targetEscape,
    midY,
    index,
  }) {
    const approachOffset = 34 + index * 8;
    const direction = targetEscape.x >= sourceEscape.x ? 1 : -1;
    const points = [source, sourceEscape];
    let headerStartX = sourceEscape.x;

    if (sourceSide === "top" || sourceSide === "bottom") {
      headerStartX = sourceEscape.x + direction * approachOffset;
      points.push({ x: headerStartX, y: sourceEscape.y });
    }

    points.push({ x: headerStartX, y: midY });

    if (targetSide === "top" || targetSide === "bottom") {
      const targetApproachX = targetEscape.x - direction * approachOffset;

      points.push(
        { x: targetApproachX, y: midY },
        { x: targetApproachX, y: targetEscape.y },
        targetEscape,
        target
      );
    } else {
      points.push({ x: targetEscape.x, y: midY }, targetEscape, target);
    }

    return this.compactPoints(points);
  }

  labelCandidatesForSegments(segments, laneStackBounds = null) {
    const verticalSegments = segments.filter(
      (segment) => segment.x1 === segment.x2
    );
    const candidateSegments = verticalSegments.length
      ? verticalSegments
      : segments;
    const longestSegment = candidateSegments.reduce((longest, segment) => {
      return this.segmentLength(segment) > this.segmentLength(longest)
        ? segment
        : longest;
    }, candidateSegments[0]);

    const ratioCandidates = [
      { ratio: 1 / 2, penalty: 0 },
      { ratio: 1 / 3, penalty: 0 },
      { ratio: 2 / 3, penalty: 0 },
      { ratio: 1 / 4, penalty: 0 },
      { ratio: 3 / 4, penalty: 0 },
      { ratio: 1 / 5, penalty: 0 },
      { ratio: 4 / 5, penalty: 0 },
      { ratio: 1 / 10, penalty: 0 },
      { ratio: 9 / 10, penalty: 0 },
      { ratio: 1 / 20, penalty: 0 },
    ].map((candidate) => {
      return {
        point: {
          x:
            longestSegment.x1 +
            (longestSegment.x2 - longestSegment.x1) * candidate.ratio,
          y:
            longestSegment.y1 +
            (longestSegment.y2 - longestSegment.y1) * candidate.ratio,
        },
        penalty: candidate.penalty,
      };
    });

    return [
      ...this.laneWhitespaceLabelCandidatesForSegment(
        longestSegment,
        laneStackBounds
      ),
      ...ratioCandidates,
    ];
  }

  laneWhitespaceLabelCandidatesForSegment(segment, laneStackBounds) {
    if (!laneStackBounds?.lanes?.length || segment.x1 !== segment.x2) {
      return [];
    }

    const segmentTop = Math.min(segment.y1, segment.y2);
    const segmentBottom = Math.max(segment.y1, segment.y2);

    return laneStackBounds.lanes
      .map((lane) => {
        const contentTop = lane.labelBottom ?? lane.top;
        const contentBottom = lane.bottom;
        const contentCenter = (contentTop + contentBottom) / 2;

        if (
          segment.x1 < (lane.contentLeft ?? lane.left) ||
          segment.x1 > (lane.contentRight ?? lane.right) ||
          contentCenter < segmentTop ||
          contentCenter > segmentBottom
        ) {
          return null;
        }

        return {
          point: {
            x: segment.x1,
            y: contentCenter,
          },
          penalty: -30,
        };
      })
      .filter(Boolean);
  }

  segmentLength(segment) {
    return (
      Math.abs(segment.x2 - segment.x1) + Math.abs(segment.y2 - segment.y1)
    );
  }

  pointsToPath(points) {
    const [firstPoint, ...remainingPoints] = this.compactPoints(points);
    const commands = [`M${firstPoint.x},${firstPoint.y}`];
    let previous = firstPoint;

    for (const point of remainingPoints) {
      if (point.x === previous.x) {
        commands.push(`V${point.y}`);
      } else if (point.y === previous.y) {
        commands.push(`H${point.x}`);
      } else {
        commands.push(`L${point.x},${point.y}`);
      }

      previous = point;
    }

    return commands.join(" ");
  }

  compactPoints(points) {
    return points.filter((point, index) => {
      const previous = points[index - 1];
      return !previous || previous.x !== point.x || previous.y !== point.y;
    });
  }

  endpointKey(stepId, side) {
    return `${stepId}:${side}`;
  }

  connectorEndpointInUse({ stepId, side, ignoredStepOptionId }) {
    return this.edgeLayouts.some((edge) => {
      return (
        edge.step_option.id !== ignoredStepOptionId &&
        ((edge.source_step_id === stepId && edge.source_side === side) ||
          (edge.target_step_id === stepId && edge.target_side === side))
      );
    });
  }

  legacyEdgeRoute({
    allRects,
    index,
    sourceRect,
    targetRect,
    sourceStep,
    targetStep,
  }) {
    const sourcePosition = sourceStep.position || 0;
    const targetPosition = targetStep.position || 0;
    const obstacleRects = this.obstacleRects(
      allRects,
      sourceStep.id,
      targetStep.id
    );

    if (targetPosition > sourcePosition) {
      return this.forwardEdgeRoute(
        index,
        sourceRect,
        targetRect,
        obstacleRects
      );
    }

    if (targetPosition < sourcePosition) {
      return this.returnEdgeRoute(index, sourceRect, targetRect, obstacleRects);
    }

    return this.sameColumnEdgeRoute(
      index,
      sourceRect,
      targetRect,
      obstacleRects
    );
  }

  forwardEdgeRoute(index, sourceRect, targetRect, obstacleRects) {
    const source = {
      x: sourceRect.right,
      y: sourceRect.centerY,
    };
    const target = {
      x: targetRect.left,
      y: targetRect.centerY,
    };
    const baseMidX = (source.x + target.x) / 2 + this.routeOffset(index, 12);
    const candidates = this.routingCandidates(baseMidX, 48);
    const midX =
      candidates.find((candidate) => {
        return !this.pathCollides(
          [
            { x1: source.x, y1: source.y, x2: candidate, y2: source.y },
            { x1: candidate, y1: source.y, x2: candidate, y2: target.y },
            { x1: candidate, y1: target.y, x2: target.x, y2: target.y },
          ],
          obstacleRects
        );
      }) || baseMidX;

    return {
      path: `M${source.x},${source.y} H${midX} V${target.y} H${target.x}`,
      label_x: midX,
      label_y: (source.y + target.y) / 2,
    };
  }

  returnEdgeRoute(index, sourceRect, targetRect, obstacleRects) {
    const source = {
      x: sourceRect.centerX,
      y: sourceRect.top,
    };
    const target = {
      x: targetRect.centerX,
      y: targetRect.top,
    };
    const baseReturnY =
      Math.min(sourceRect.top, targetRect.top) -
      24 -
      this.routeOffset(index, 18);
    const candidates = Array.from({ length: 8 }, (_, offset) => {
      return baseReturnY - offset * 18;
    });
    const returnY =
      candidates.find((candidate) => {
        return !this.pathCollides(
          [
            { x1: source.x, y1: source.y, x2: source.x, y2: candidate },
            { x1: source.x, y1: candidate, x2: target.x, y2: candidate },
            { x1: target.x, y1: candidate, x2: target.x, y2: target.y },
          ],
          obstacleRects
        );
      }) || baseReturnY;

    return {
      path: `M${source.x},${source.y} V${returnY} H${target.x} V${target.y}`,
      label_x: (source.x + target.x) / 2,
      label_y: returnY,
    };
  }

  sameColumnEdgeRoute(index, sourceRect, targetRect, obstacleRects) {
    const sourceAboveTarget = sourceRect.centerY <= targetRect.centerY;
    const source = {
      x: sourceRect.centerX,
      y: sourceAboveTarget ? sourceRect.bottom : sourceRect.top,
    };
    const target = {
      x: targetRect.centerX,
      y: sourceAboveTarget ? targetRect.top : targetRect.bottom,
    };
    const baseSideX =
      Math.max(sourceRect.right, targetRect.right) +
      24 +
      this.routeOffset(index, 12);
    const midY = (source.y + target.y) / 2;
    const candidates = Array.from({ length: 8 }, (_, offset) => {
      return baseSideX + offset * 18;
    });
    const sideX =
      candidates.find((candidate) => {
        return !this.pathCollides(
          [
            { x1: source.x, y1: source.y, x2: source.x, y2: midY },
            { x1: source.x, y1: midY, x2: candidate, y2: midY },
            { x1: candidate, y1: midY, x2: candidate, y2: target.y },
            { x1: candidate, y1: target.y, x2: target.x, y2: target.y },
          ],
          obstacleRects
        );
      }) || baseSideX;

    return {
      path: `M${source.x},${source.y} V${midY} H${sideX} V${target.y} H${target.x}`,
      label_x: sideX,
      label_y: midY,
    };
  }

  obstacleRects(allRects, sourceStepId, targetStepId) {
    return [...allRects.entries()]
      .filter(([stepId]) => {
        return stepId !== sourceStepId && stepId !== targetStepId;
      })
      .map(([, rect]) => rect);
  }

  routingCandidates(baseValue, stepSize) {
    return Array.from({ length: 40 }, (_, index) => {
      if (index === 0) {
        return baseValue;
      }

      const direction = index % 2 === 0 ? -1 : 1;
      const multiplier = Math.ceil(index / 2);
      return baseValue + direction * multiplier * stepSize;
    });
  }

  pathCollides(segments, rects, padding = this.routeObstaclePadding) {
    return segments.some((segment) => {
      return rects.some((rect) => {
        return this.segmentIntersectsRect(segment, rect, padding);
      });
    });
  }

  nonEndpointSegments(segments) {
    return segments.slice(1, -1);
  }

  get routeObstaclePadding() {
    return 36;
  }

  segmentIntersectsRect(segment, rect, padding) {
    const left = rect.left - padding;
    const right = rect.right + padding;
    const top = rect.top - padding;
    const bottom = rect.bottom + padding;
    const minX = Math.min(segment.x1, segment.x2);
    const maxX = Math.max(segment.x1, segment.x2);
    const minY = Math.min(segment.y1, segment.y2);
    const maxY = Math.max(segment.y1, segment.y2);

    if (segment.y1 === segment.y2) {
      return (
        segment.y1 >= top &&
        segment.y1 <= bottom &&
        maxX >= left &&
        minX <= right
      );
    }

    if (segment.x1 === segment.x2) {
      return (
        segment.x1 >= left &&
        segment.x1 <= right &&
        maxY >= top &&
        minY <= bottom
      );
    }

    return false;
  }

  routeOffset(index, size) {
    return (index % 3) * size;
  }

  @bind
  edgeOptionStyle(edge) {
    const x = Number(edge.label_x);
    const y = Number(edge.label_y);

    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      return null;
    }

    return trustHTML(`left: ${x}px; top: ${y}px;`);
  }

  hexColor(rawColor) {
    if (!rawColor) {
      return null;
    }

    const normalized = String(rawColor).trim().replace(/^#/, "");
    if (!normalized.match(/^[0-9A-Fa-f]{3}$|^[0-9A-Fa-f]{6}$/)) {
      return null;
    }

    return `#${normalized}`;
  }

  @action
  dragStepStart(step) {
    this.draggedStepId = step.id;
  }

  @action
  dragStepEnd() {
    this.draggedStepId = null;
    this.scheduleEdgeLayout();
  }

  @action
  allowDrop(event) {
    event.preventDefault();
  }

  boardPointForEvent(event) {
    const boardRect = this.boardElement.getBoundingClientRect();

    return {
      x: event.clientX - boardRect.left,
      y: event.clientY - boardRect.top,
    };
  }

  stepRect(stepId) {
    const boardRect = this.boardElement.getBoundingClientRect();
    const element = this.boardElement.querySelector(
      `[data-workflow-step-id="${stepId}"]`
    );

    if (!element) {
      return null;
    }

    const rect = element.getBoundingClientRect();

    return {
      left: rect.left - boardRect.left,
      right: rect.right - boardRect.left,
      top: rect.top - boardRect.top,
      bottom: rect.bottom - boardRect.top,
      width: rect.width,
      height: rect.height,
      centerX: rect.left - boardRect.left + rect.width / 2,
      centerY: rect.top - boardRect.top + rect.height / 2,
    };
  }

  updateConnectorPreview(point, targetSide = null) {
    if (!this.boardElement || !this.connectorDragMode) {
      this.previewPath = null;
      return;
    }

    const fixedStepId =
      this.connectorDragMode === "retarget-source"
        ? this.connectorTargetStepId
        : this.connectorSourceStepId;
    const fixedSide =
      this.connectorDragMode === "retarget-source"
        ? this.connectorTargetSide
        : this.connectorSourceSide;
    const fixedRect = this.stepRect(fixedStepId);

    if (!fixedRect) {
      this.previewPath = null;
      return;
    }

    const allRects = new Map();
    const laneStackBounds = this.laneStackBounds(
      this.boardElement.getBoundingClientRect()
    );
    for (const step of this.workflowSteps) {
      const rect = this.stepRect(step.id);

      if (rect) {
        allRects.set(step.id, rect);
      }
    }

    const obstacleRects = [...allRects.entries()]
      .filter(([stepId]) => stepId !== fixedStepId)
      .map(([, rect]) => rect);
    const labelObstacleRects = [...allRects.values()];
    const fixedPoint = this.connectorPoint(fixedRect, fixedSide);
    const route =
      this.connectorDragMode === "retarget-source"
        ? this.routePoints({
            index: this.edgeLayouts.length + 1,
            source: point,
            sourceSide: targetSide,
            target: fixedPoint,
            targetSide: fixedSide,
            obstacleRects,
            labelObstacleRects,
            laneStackBounds,
          })
        : this.routePoints({
            index: this.edgeLayouts.length + 1,
            source: fixedPoint,
            sourceSide: fixedSide,
            target: point,
            targetSide,
            obstacleRects,
            labelObstacleRects,
            laneStackBounds,
          });

    this.previewPath = route.path;
  }

  clearConnectorDrag() {
    this.previewPath = null;
    this.draggedOptionId = null;
    this.linkSourceStepId = null;
    this.connectorDragMode = null;
    this.connectorSourceStepId = null;
    this.connectorSourceSide = null;
    this.connectorTargetStepId = null;
    this.connectorTargetSide = null;
  }

  @action
  dragConnectorOverBoard(event) {
    if (!this.connectorDragMode) {
      return;
    }

    event.preventDefault();
    this.updateConnectorPreview(this.boardPointForEvent(event));
  }

  @action
  dragConnectorHandleStart(step, side, event) {
    event.stopPropagation();

    const targetEdge = this.edgeForTargetHandle(step, side);
    const sourceEdge = this.edgeForSourceHandle(step, side);

    if (targetEdge) {
      this.connectorDragMode = "retarget-target";
      this.draggedOptionId = targetEdge.step_option.id;
      this.connectorSourceStepId = targetEdge.source_step_id;
      this.connectorSourceSide = targetEdge.source_side;
      this.connectorTargetStepId = step.id;
      this.connectorTargetSide = side;
    } else if (sourceEdge) {
      this.connectorDragMode = "retarget-source";
      this.draggedOptionId = sourceEdge.step_option.id;
      this.connectorSourceStepId = step.id;
      this.connectorSourceSide = side;
      this.connectorTargetStepId = sourceEdge.target_step_id;
      this.connectorTargetSide = sourceEdge.target_side;
    } else {
      this.connectorDragMode = "create";
      this.linkSourceStepId = step.id;
      this.connectorSourceStepId = step.id;
      this.connectorSourceSide = side;
    }

    this.updateConnectorPreview(this.boardPointForEvent(event));
  }

  @action
  dragConnectorHandleOver(step, side, event) {
    if (!this.connectorDragMode) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    const rect = this.stepRect(step.id);

    if (!rect) {
      return;
    }

    this.updateConnectorPreview(this.connectorPoint(rect, side), side);
  }

  @action
  async dropConnectorHandle(targetStep, targetSide, event) {
    if (!this.connectorDragMode) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    const sourceStepId =
      this.connectorDragMode === "retarget-source"
        ? targetStep.id
        : this.connectorSourceStepId;
    const sourceSide =
      this.connectorDragMode === "retarget-source"
        ? targetSide
        : this.connectorSourceSide;
    const finalTargetStepId =
      this.connectorDragMode === "retarget-source"
        ? this.connectorTargetStepId
        : targetStep.id;
    const finalTargetSide =
      this.connectorDragMode === "retarget-source"
        ? this.connectorTargetSide
        : targetSide;

    if (
      sourceStepId === finalTargetStepId ||
      this.connectorEndpointInUse({
        stepId: sourceStepId,
        side: sourceSide,
        ignoredStepOptionId: this.draggedOptionId,
      }) ||
      this.connectorEndpointInUse({
        stepId: finalTargetStepId,
        side: finalTargetSide,
        ignoredStepOptionId: this.draggedOptionId,
      })
    ) {
      this.clearConnectorDrag();
      return;
    }

    try {
      if (this.connectorDragMode === "create") {
        await this.createLink(finalTargetStepId);
      } else if (this.connectorDragMode === "retarget-source") {
        await this.retargetOptionSource(sourceStepId);
      } else {
        await this.retargetOption(finalTargetStepId);
      }
    } catch (err) {
      popupAjaxError(err);
    } finally {
      this.clearConnectorDrag();
    }
  }

  @action
  dragConnectorHandleEnd() {
    this.clearConnectorDrag();
    this.scheduleEdgeLayout();
  }

  @action
  async dropStepOnLane(lane, event) {
    event.preventDefault();

    const step = this.workflowSteps.find(
      (workflowStep) => workflowStep.id === this.draggedStepId
    );

    if (!step || step.category_id === lane.id) {
      this.draggedStepId = null;
      return;
    }

    try {
      await this.updateStep(step, { category_id: lane.id });
      await this.reloadGraphInPlace();
    } catch (err) {
      popupAjaxError(err);
    } finally {
      this.draggedStepId = null;
    }
  }

  @action
  async dropStepOnLanePosition(lane, position, event) {
    event.preventDefault();

    const sourceStep = this.workflowSteps.find(
      (workflowStep) => workflowStep.id === this.draggedStepId
    );

    if (
      !sourceStep ||
      (sourceStep.category_id === lane.id && sourceStep.position === position)
    ) {
      this.draggedStepId = null;
      return;
    }

    const targetStep = this.workflowSteps.find((workflowStep) => {
      return (
        workflowStep.id !== sourceStep.id && workflowStep.position === position
      );
    });

    try {
      if (targetStep) {
        await this.updateStep(targetStep, { position: sourceStep.position });
      }

      await this.updateStep(sourceStep, {
        category_id: lane.id,
        position,
      });
      await this.reloadGraphInPlace();
    } catch (err) {
      popupAjaxError(err);
    } finally {
      this.draggedStepId = null;
    }
  }

  async reorderStep(targetStep) {
    const sourceStep = this.workflowSteps.find(
      (step) => step.id === this.draggedStepId
    );

    if (!sourceStep || sourceStep.id === targetStep.id) {
      return;
    }

    const sourcePosition = sourceStep.position;
    await this.updateStep(targetStep, { position: sourcePosition });
    await this.updateStep(sourceStep, { position: targetStep.position });
    await this.reloadGraphInPlace();
  }

  @action
  async dropOnStep(targetStep, event) {
    event.preventDefault();
    event.stopPropagation();

    try {
      if (this.draggedStepId) {
        await this.reorderStep(targetStep);
      }
    } catch (err) {
      popupAjaxError(err);
    } finally {
      this.draggedStepId = null;
    }
  }

  @action
  dragLinkStart(step, event) {
    event.stopPropagation();
    this.linkSourceStepId = step.id;
  }

  @action
  clearLinkSource() {
    this.linkSourceStepId = null;
  }

  async createLink(targetStepId) {
    const sourceStep = this.workflowSteps.find(
      (step) => step.id === this.linkSourceStepId
    );
    const workflowOptionId = this.defaultWorkflowOptionId;

    if (!sourceStep || !workflowOptionId || sourceStep.id === targetStepId) {
      return;
    }

    await ajax("/admin/plugins/discourse-workflow/workflow_step_options.json", {
      type: "POST",
      data: {
        workflow_step_option: {
          workflow_step_id: sourceStep.id,
          workflow_option_id: workflowOptionId,
          target_step_id: targetStepId,
          position: this.stepOptions(sourceStep).length + 1,
        },
      },
    });
    await this.reloadGraphInPlace();
  }

  @action
  dragOptionStart(stepOption, event) {
    event.stopPropagation();
    this.draggedOptionId = stepOption.id;
  }

  @action
  dragOptionEnd() {
    this.draggedOptionId = null;
  }

  async retargetOption(targetStepId) {
    const stepOption = this.workflowSteps
      .flatMap((step) => step.workflow_step_options || [])
      .find((option) => option.id === this.draggedOptionId);

    if (!stepOption || stepOption.target_step_id === targetStepId) {
      return;
    }

    await this.updateStepOption(stepOption, { target_step_id: targetStepId });
    await this.reloadGraphInPlace();
  }

  async retargetOptionSource(sourceStepId) {
    const stepOption = this.workflowSteps
      .flatMap((step) => step.workflow_step_options || [])
      .find((option) => option.id === this.draggedOptionId);

    if (!stepOption || stepOption.workflow_step_id === sourceStepId) {
      return;
    }

    const sourceStep = this.workflowSteps.find(
      (step) => step.id === sourceStepId
    );

    await this.updateStepOption(stepOption, {
      workflow_step_id: sourceStepId,
      position: sourceStep ? this.stepOptions(sourceStep).length + 1 : 1,
    });
    await this.reloadGraphInPlace();
  }

  @action
  async updateStepOptionName(stepOption, event) {
    try {
      await this.updateStepOption(stepOption, {
        workflow_option_id: parseInt(event.target.value, 10),
      });
      await this.reloadGraphInPlace();
    } catch (err) {
      popupAjaxError(err);
    }
  }

  @action
  updateNewStepCategory(categoryId) {
    this.newStepCategoryId = categoryId;
  }

  @action
  addStepToLane(lane) {
    this.router.transitionTo(
      "adminPlugins.show.discourse-workflow-workflows.steps.new",
      this.args.workflow,
      {
        queryParams: {
          category_id: lane.id,
        },
      }
    );
  }

  @action
  async addStep() {
    if (!this.newStepCategoryId) {
      return;
    }

    try {
      await ajax("/admin/plugins/discourse-workflow/workflow_steps.json", {
        type: "POST",
        data: {
          workflow_step: {
            workflow_id: this.args.workflow.id,
            name:
              this.newStepName ||
              i18n(
                "admin.discourse_workflow.workflows.visual.default_step_name",
                {
                  position: this.nextStepPosition,
                }
              ),
            category_id: this.newStepCategoryId,
            position: this.nextStepPosition,
          },
        },
      });
      this.newStepName = "";
      await this.reloadGraphInPlace();
    } catch (err) {
      popupAjaxError(err);
    }
  }

  <template>
    <section
      class="workflow-visual-editor"
      {{didInsert this.registerTestInterface}}
      {{didInsert this.loadGraph}}
    >
      <div class="workflow-visual-editor__add-step">
        <Input
          class="workflow-visual-editor__new-step-name"
          @value={{this.newStepName}}
          placeholder={{i18n
            "admin.discourse_workflow.workflows.visual.new_step_name"
          }}
        />
        <CategoryChooser
          @value={{this.newStepCategoryId}}
          @onChangeCategory={{this.updateNewStepCategory}}
        />
        <DButton
          class="btn-primary workflow-visual-editor__add-step-button"
          @action={{this.addStep}}
          @label="admin.discourse_workflow.workflows.visual.add_step"
          @title="admin.discourse_workflow.workflows.visual.add_step_title"
          @disabled={{@disabled}}
        />
      </div>

      {{#if this.isLoading}}
        <p>{{i18n "admin.discourse_workflow.workflows.visual.loading"}}</p>
      {{else if this.hasSteps}}
        <div
          class="workflow-visual-editor__board"
          {{didInsert this.captureBoard}}
          {{didUpdate
            this.scheduleEdgeLayout
            this.workflowSteps
            this.workflowCategories
          }}
          {{on "dragover" this.dragConnectorOverBoard}}
        >
          <svg class="workflow-visual-editor__edge-layer" aria-hidden="true">
            <defs>
              <marker
                id="workflow-visual-editor-arrowhead"
                markerHeight="8"
                markerWidth="10"
                orient="auto"
                refX="9"
                refY="4"
                viewBox="0 0 10 8"
              >
                <path d="M0,0 L10,4 L0,8 Z"></path>
              </marker>
            </defs>
            {{#each this.edgeLayouts as |edge|}}
              <path
                class="workflow-visual-editor__edge-path"
                data-workflow-step-option-id={{edge.step_option.id}}
                data-workflow-source-step-id={{edge.source_step_id}}
                data-workflow-target-step-id={{edge.target_step_id}}
                data-workflow-source-side={{edge.source_side}}
                data-workflow-target-side={{edge.target_side}}
                d={{edge.path}}
              ></path>
            {{/each}}
            {{#if this.previewPath}}
              <path
                class="workflow-visual-editor__edge-path workflow-visual-editor__edge-path--preview"
                d={{this.previewPath}}
              ></path>
            {{/if}}
          </svg>

          <div class="workflow-visual-editor__edge-controls">
            {{#each this.edgeLayouts as |edge|}}
              <div
                class="workflow-visual-editor__option"
                data-workflow-step-option-id={{edge.step_option.id}}
                style={{this.edgeOptionStyle edge}}
              >
                <DButton
                  class="btn-danger btn-small workflow-visual-editor__delete-option"
                  @icon="xmark"
                  @title="admin.discourse_workflow.workflows.visual.delete_connector"
                  @action={{fn this.confirmDeleteStepOption edge.step_option}}
                  @disabled={{@disabled}}
                />
                <select
                  data-workflow-step-option-id={{edge.step_option.id}}
                  title={{i18n
                    "admin.discourse_workflow.workflows.visual.change_connector_option"
                  }}
                  value={{edge.step_option.workflow_option_id}}
                  {{on
                    "change"
                    (fn this.updateStepOptionName edge.step_option)
                  }}
                >
                  {{#each this.workflowOptions as |workflowOption|}}
                    <option
                      value={{workflowOption.id}}
                      selected={{this.isWorkflowOptionSelected
                        edge.step_option
                        workflowOption
                      }}
                    >
                      {{this.workflowOptionLabel workflowOption.id}}
                    </option>
                  {{/each}}
                </select>
              </div>
            {{/each}}
          </div>

          <div class="workflow-visual-editor__lanes">
            {{#each this.lanes as |lane|}}
              <section
                class="workflow-visual-editor__lane"
                data-workflow-category-id={{lane.id}}
                style={{this.laneStyle lane}}
                {{on "dragover" this.allowDrop}}
                {{on "drop" (fn this.dropStepOnLane lane)}}
              >
                <header class="workflow-visual-editor__lane-header">
                  <span class="workflow-visual-editor__lane-title">
                    {{lane.name}}
                  </span>
                  <DButton
                    class="btn-small btn-default workflow-visual-editor__add-step-to-lane"
                    @icon="plus"
                    @title="admin.discourse_workflow.workflows.visual.add_step_to_lane"
                    @action={{fn this.addStepToLane lane}}
                    @disabled={{@disabled}}
                  />
                </header>

                <div class="workflow-visual-editor__lane-steps">
                  {{#each this.positionSlots as |position|}}
                    <div
                      class="workflow-visual-editor__position-slot"
                      data-workflow-category-id={{lane.id}}
                      data-workflow-position={{position}}
                      {{on "dragover" this.allowDrop}}
                      {{on
                        "drop"
                        (fn this.dropStepOnLanePosition lane position)
                      }}
                    >
                      {{#each
                        (this.stepsForLanePosition lane position)
                        as |step|
                      }}
                        <article
                          class="workflow-visual-editor__step"
                          data-workflow-step-id={{step.id}}
                          draggable={{if @disabled false true}}
                          {{on "dragstart" (fn this.dragStepStart step)}}
                          {{on "dragend" this.dragStepEnd}}
                          {{on "dragover" this.allowDrop}}
                          {{on "drop" (fn this.dropOnStep step)}}
                        >
                          <DButton
                            class="btn-danger btn-small workflow-visual-editor__delete-step"
                            @icon="xmark"
                            @title="admin.discourse_workflow.workflows.visual.delete_step"
                            @action={{fn this.confirmDeleteStep step}}
                            @disabled={{@disabled}}
                          />

                          {{#each this.connectorSides as |side|}}
                            <button
                              type="button"
                              class={{this.connectorHandleClass step side}}
                              aria-label={{this.connectorHandleLabel step side}}
                              title={{this.connectorHandleLabel step side}}
                              data-workflow-connector-side={{side}}
                              draggable={{if @disabled false true}}
                              {{on
                                "dragstart"
                                (fn this.dragConnectorHandleStart step side)
                              }}
                              {{on
                                "dragover"
                                (fn this.dragConnectorHandleOver step side)
                              }}
                              {{on
                                "drop"
                                (fn this.dropConnectorHandle step side)
                              }}
                              {{on "dragend" this.dragConnectorHandleEnd}}
                            ></button>
                          {{/each}}

                          <div class="workflow-visual-editor__step-title">
                            <span class="workflow-visual-editor__step-number">
                              {{step.position}}.
                            </span>
                            <strong class="workflow-visual-editor__step-label">
                              {{step.name}}
                            </strong>
                          </div>
                        </article>
                      {{/each}}
                    </div>
                  {{/each}}
                </div>
              </section>
            {{/each}}
          </div>
        </div>
      {{else}}
        <div
          class="workflow-visual-editor__board"
          {{didInsert this.captureBoard}}
        >
          <p class="workflow-visual-editor__empty">
            {{i18n "admin.discourse_workflow.workflows.steps.none"}}
          </p>
        </div>
      {{/if}}
    </section>
  </template>
}
