import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action, get, set } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import categoryColorVariable from "discourse/helpers/category-color-variable";
import discourseTags from "discourse/helpers/discourse-tags";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const STORAGE_KEY = "discourse_workflow_quick_filters";

export default class WorkflowQuickFiltersConnector extends Component {
  @service dialog;
  @service discovery;
  @service router;

  @tracked stepPosition = "";
  @tracked workflowView = null;
  @tracked draggedTopicId = null;
  @tracked draggedFromPosition = null;
  @tracked transitionInFlightTopicId = null;
  @tracked recentlyDraggedTopicId = null;

  willDestroy(...args) {
    super.willDestroy(...args);

    if (typeof document !== "undefined") {
      document.body.classList.remove("workflow-kanban-view");
    }
  }

  clearDragState(topicId = null) {
    const normalizedTopicId = Number(topicId || this.draggedTopicId);

    if (normalizedTopicId) {
      this.recentlyDraggedTopicId = normalizedTopicId;
      setTimeout(() => {
        if (Number(this.recentlyDraggedTopicId) === normalizedTopicId) {
          this.recentlyDraggedTopicId = null;
        }
      }, 150);
    }

    this.draggedTopicId = null;
    this.draggedFromPosition = null;
  }

  sanitizeFilters(filters) {
    const sanitized = {};

    if (filters?.my_categories === "1") {
      sanitized.my_categories = "1";
    }

    if (filters?.overdue === "1") {
      sanitized.overdue = "1";
    }

    if (filters?.overdue_days) {
      sanitized.overdue_days = String(filters.overdue_days);
    }

    if (filters?.workflow_step_position) {
      sanitized.workflow_step_position = String(filters.workflow_step_position);
    }

    if (
      filters?.workflow_view === "kanban" ||
      filters?.workflow_view === "chart"
    ) {
      sanitized.workflow_view = filters.workflow_view;
    }

    if (filters?.chart_weeks) {
      const normalizedWeeks = this.normalizedChartWeeks(filters.chart_weeks);
      if (normalizedWeeks) {
        sanitized.chart_weeks = String(normalizedWeeks);
      }
    }

    return sanitized;
  }

  normalizedChartWeeks(value) {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 1) {
      return null;
    }

    return Math.min(parsed, 12);
  }

  get routeTopicList() {
    const routeAttributes = this.router.currentRoute?.attributes;

    return (
      routeAttributes?.list ||
      routeAttributes?.model?.list ||
      routeAttributes?.model ||
      routeAttributes
    );
  }

  get topicList() {
    return this.routeTopicList || this.discovery.currentTopicList;
  }

  get topicListMetadata() {
    try {
      return this.topicList?.topic_list || this.topicList;
    } catch {
      return this.topicList;
    }
  }

  get hasWorkflowFilter() {
    return this.topicList?.filter?.toString() === "workflow";
  }

  get currentLocation() {
    // Consume router state so this getter recomputes on in-app transitions.
    this.router.currentURL;

    if (typeof window !== "undefined") {
      return `${window.location.pathname}${window.location.search}`;
    }

    return this.router.currentURL || "";
  }

  get currentPathname() {
    return this.currentLocation.split("?")[0];
  }

  get currentSearchParams() {
    const queryString = this.currentLocation.split("?")[1] || "";
    return new URLSearchParams(queryString);
  }

  get isWorkflowRoute() {
    return (
      this.hasWorkflowFilter ||
      this.router.currentRouteName?.startsWith("discovery.workflow") ||
      this.currentPathname.startsWith("/workflow") ||
      this.currentPathname.startsWith("/filter/workflow")
    );
  }

  get isWorkflowChartsRoute() {
    return (
      this.router.currentRouteName === "discovery.workflowCharts" ||
      this.currentPathname.startsWith("/workflow/charts")
    );
  }

  get hasMyCategoriesFilter() {
    return this.currentSearchParams.get("my_categories") === "1";
  }

  get hasOverdueFilter() {
    if (this.currentSearchParams.get("overdue") === "1") {
      return true;
    }

    return (this.currentSearchParams.get("overdue_days") || "").length > 0;
  }

  get hasStepFilter() {
    return !!this.currentSearchParams.get("workflow_step_position");
  }

  get isKanbanView() {
    return this.workflowView === "kanban";
  }

  get isChartView() {
    return this.workflowView === "chart" || this.isWorkflowChartsRoute;
  }

  get canUseKanbanView() {
    try {
      return this.topicListMetadata?.workflow_kanban_compatible === true;
    } catch {
      return false;
    }
  }

  get canUseChartView() {
    try {
      return (
        this.topicListMetadata?.workflow_can_view_charts === true &&
        Number(this.topicListMetadata?.workflow_single_workflow_id) > 0
      );
    } catch {
      return false;
    }
  }

  get showKanbanTags() {
    return this.topicListMetadata?.workflow_kanban_show_tags !== false;
  }

  get currentWorkflowView() {
    if (this.isChartView) {
      return "chart";
    }

    if (this.isKanbanView) {
      return "kanban";
    }

    return "list";
  }

  get showChartViewOption() {
    return this.isChartView || this.canUseChartView;
  }

  get showWorkflowViewSelector() {
    return this.canUseKanbanView || this.showChartViewOption;
  }

  get shouldRenderKanbanBoard() {
    return this.canUseKanbanView && this.isKanbanView;
  }

  get chartWeekOptions() {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  }

  get chartWeeksValue() {
    return String(
      this.normalizedChartWeeks(this.currentSearchParams.get("chart_weeks")) ||
        2
    );
  }

  get kanbanWorkflowName() {
    try {
      return this.topicListMetadata?.workflow_kanban_workflow_name;
    } catch {
      return null;
    }
  }

  get kanbanSteps() {
    try {
      const steps = this.topicListMetadata?.workflow_kanban_steps || [];
      return [...steps].sort((left, right) => left.position - right.position);
    } catch {
      return [];
    }
  }

  get kanbanTransitionMap() {
    try {
      const transitions =
        this.topicListMetadata?.workflow_kanban_transitions || [];
      const transitionMap = new Map();

      transitions.forEach((transition) => {
        const fromPosition = Number(transition.from_position);
        const toPosition = Number(transition.to_position);
        const optionSlug = transition.option_slug;

        if (!fromPosition || !toPosition || !optionSlug) {
          return;
        }

        transitionMap.set(`${fromPosition}:${toPosition}`, optionSlug);
      });

      return transitionMap;
    } catch {
      return new Map();
    }
  }

  get kanbanStepNames() {
    return this.kanbanSteps.reduce((accumulator, step) => {
      accumulator[Number(step.position)] = step.name;
      return accumulator;
    }, {});
  }

  optionSlugForTransition(fromPosition, toPosition) {
    return this.kanbanTransitionMap.get(`${fromPosition}:${toPosition}`);
  }

  adjacentStepPosition(fromPosition, direction) {
    const positions = this.kanbanSteps.map((step) => Number(step.position));
    const index = positions.indexOf(Number(fromPosition));

    if (index === -1) {
      return null;
    }

    const nextPosition = positions[index + direction];
    return Number.isInteger(nextPosition) ? nextPosition : null;
  }

  isColumnLegalDropTarget(position) {
    if (!this.draggedTopicId || !this.draggedFromPosition) {
      return false;
    }

    if (Number(position) === Number(this.draggedFromPosition)) {
      return true;
    }

    return !!this.optionSlugForTransition(
      Number(this.draggedFromPosition),
      Number(position)
    );
  }

  dropStateForColumn(position) {
    if (!this.draggedTopicId || !this.draggedFromPosition) {
      return null;
    }

    if (Number(position) === Number(this.draggedFromPosition)) {
      return "source";
    }

    return this.isColumnLegalDropTarget(position) ? "legal" : "illegal";
  }

  getTopicListSafe() {
    try {
      const topicCollection =
        this.discovery.currentTopicList?.topics ||
        this.topicList?.topics ||
        this.topicListMetadata?.topics ||
        this.topicListMetadata?.topic_list?.topics ||
        [];
      return Array.isArray(topicCollection) ? topicCollection : [];
    } catch {
      return [];
    }
  }

  get kanbanColumns() {
    const topics = this.getTopicListSafe();

    return this.kanbanSteps.map((step) => {
      const position = Number(step.position);
      const stepTopics = topics
        .filter(
          (topic) =>
            Number(
              get(topic, "workflow_step_position") ||
                get(topic, "workflowStepPosition")
            ) === position
        )
        .map((topic) => ({
          id: get(topic, "id"),
          title: get(topic, "title"),
          workflow_step_position: Number(
            get(topic, "workflow_step_position") ||
              get(topic, "workflowStepPosition")
          ),
          workflow_overdue: !!get(topic, "workflow_overdue"),
          workflow_can_act: !!get(topic, "workflow_can_act"),
          tags: get(topic, "tags") || [],
          workflow_topic_url:
            get(topic, "url") ||
            (get(topic, "slug")
              ? `/t/${get(topic, "slug")}/${get(topic, "id")}`
              : `/t/${get(topic, "id")}`),
          is_transitioning:
            Number(get(topic, "id")) === Number(this.transitionInFlightTopicId),
          is_dragging: Number(get(topic, "id")) === Number(this.draggedTopicId),
        }));

      const dropState = this.dropStateForColumn(position);
      const columnClasses = ["workflow-kanban__column"];

      if (dropState) {
        columnClasses.push(`workflow-kanban__column--${dropState}`);
      }

      return {
        ...step,
        drop_state: dropState,
        column_class: columnClasses.join(" "),
        column_style: step.category_color
          ? categoryColorVariable(step.category_color)
          : null,
        topics: stepTopics,
        topic_count_label: i18n("discourse_workflow.kanban.topic_count", {
          count: stepTopics.length,
        }),
      };
    });
  }

  @action
  initializeFilters() {
    const params = this.currentSearchParams;
    this.stepPosition = params.get("workflow_step_position") || "";
    this.workflowView =
      params.get("workflow_view") ||
      (this.isWorkflowChartsRoute ? "chart" : null);

    if (this.isWorkflowChartsRoute) {
      return;
    }

    if (
      params.has("my_categories") ||
      params.has("overdue") ||
      params.has("overdue_days") ||
      params.has("workflow_step_position") ||
      params.has("workflow_view") ||
      params.has("chart_weeks")
    ) {
      return;
    }

    const savedFilters = this.savedFilters;
    if (!savedFilters || Object.keys(savedFilters).length === 0) {
      return;
    }

    this.navigateWithFilters(savedFilters);
  }

  get savedFilters() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
    } catch {
      return {};
    }
  }

  persistFilters(filters) {
    const sanitized = this.sanitizeFilters(filters);
    if (Object.keys(sanitized).length === 0) {
      localStorage.removeItem(STORAGE_KEY);
      return;
    }

    localStorage.setItem(STORAGE_KEY, JSON.stringify(sanitized));
  }

  navigateWithFilters(filters) {
    const sanitized = this.sanitizeFilters(filters);
    const queryParams = {
      my_categories: sanitized.my_categories || null,
      overdue: sanitized.overdue || null,
      overdue_days: sanitized.overdue_days || null,
      workflow_step_position: sanitized.workflow_step_position || null,
      workflow_view: sanitized.workflow_view || null,
      chart_weeks: sanitized.chart_weeks || null,
    };
    const currentParams = this.currentSearchParams;
    const unchanged =
      (currentParams.get("my_categories") || null) ===
        queryParams.my_categories &&
      (currentParams.get("overdue") || null) === queryParams.overdue &&
      (currentParams.get("overdue_days") || null) ===
        queryParams.overdue_days &&
      (currentParams.get("workflow_step_position") || null) ===
        queryParams.workflow_step_position &&
      (currentParams.get("workflow_view") || null) ===
        queryParams.workflow_view &&
      (currentParams.get("chart_weeks") || null) === queryParams.chart_weeks;

    if (unchanged) {
      return;
    }

    this.router.transitionTo("discovery.workflow", { queryParams });
  }

  @action
  updateStepPosition(event) {
    this.stepPosition = event.target.value;
  }

  @action
  toggleMyCategories() {
    const params = new URLSearchParams(this.currentSearchParams.toString());

    if (this.hasMyCategoriesFilter) {
      params.delete("my_categories");
    } else {
      params.set("my_categories", "1");
    }

    this.persistFilters({
      my_categories: params.get("my_categories"),
      overdue: params.get("overdue"),
      overdue_days: params.get("overdue_days"),
      workflow_step_position: params.get("workflow_step_position"),
    });
    this.navigateWithFilters(Object.fromEntries(params.entries()));
  }

  @action
  toggleOverdue() {
    const params = new URLSearchParams(this.currentSearchParams.toString());

    if (this.hasOverdueFilter) {
      params.delete("overdue");
      params.delete("overdue_days");
    } else {
      params.set("overdue", "1");
      params.delete("overdue_days");
    }

    this.persistFilters({
      my_categories: params.get("my_categories"),
      overdue: params.get("overdue"),
      overdue_days: params.get("overdue_days"),
      workflow_step_position: params.get("workflow_step_position"),
    });
    this.navigateWithFilters(Object.fromEntries(params.entries()));
  }

  @action
  applyStepFilter() {
    const params = new URLSearchParams(this.currentSearchParams.toString());
    const nextStepPosition = this.stepPosition.trim();
    const currentStepPosition = params.get("workflow_step_position") || "";

    if (nextStepPosition && nextStepPosition === currentStepPosition) {
      params.delete("workflow_step_position");
    } else if (nextStepPosition) {
      params.set("workflow_step_position", nextStepPosition);
    } else {
      params.delete("workflow_step_position");
    }

    this.persistFilters({
      my_categories: params.get("my_categories"),
      overdue: params.get("overdue"),
      overdue_days: params.get("overdue_days"),
      workflow_step_position: params.get("workflow_step_position"),
    });
    this.navigateWithFilters(Object.fromEntries(params.entries()));
  }

  @action
  clearFilters() {
    localStorage.removeItem(STORAGE_KEY);
    this.stepPosition = "";
    this.navigateWithFilters({});
  }

  @action
  changeWorkflowView(event) {
    const nextView = event.target.value;
    const params = new URLSearchParams(this.currentSearchParams.toString());

    if (nextView === "list") {
      params.delete("workflow_view");
      this.workflowView = null;
    } else if (nextView === "kanban") {
      if (!this.canUseKanbanView) {
        event.target.value = this.currentWorkflowView;
        return;
      }

      params.set("workflow_view", "kanban");
      this.workflowView = "kanban";
    } else if (nextView === "chart") {
      if (!this.canUseChartView) {
        event.target.value = this.currentWorkflowView;
        return;
      }

      params.set("workflow_view", "chart");
      if (!params.get("chart_weeks")) {
        params.set("chart_weeks", "2");
      }
      this.workflowView = "chart";
    }

    this.syncBodyClass();
    const nextFilters = Object.fromEntries(params.entries());

    if (this.isWorkflowChartsRoute) {
      this.router.transitionTo("discovery.workflow", {
        queryParams: {
          my_categories: nextFilters.my_categories || null,
          overdue: nextFilters.overdue || null,
          overdue_days: nextFilters.overdue_days || null,
          workflow_step_position: nextFilters.workflow_step_position || null,
          workflow_view: nextFilters.workflow_view || null,
          chart_weeks: nextFilters.chart_weeks || null,
        },
      });
      return;
    }

    this.navigateWithFilters(nextFilters);
  }

  @action
  changeChartWeeks(event) {
    const weeks = this.normalizedChartWeeks(event.target.value);
    if (!weeks) {
      event.target.value = this.chartWeeksValue;
      return;
    }

    const params = new URLSearchParams(this.currentSearchParams.toString());
    params.set("workflow_view", "chart");
    params.set("chart_weeks", String(weeks));
    this.navigateWithFilters(Object.fromEntries(params.entries()));
  }

  @action
  cardDragStart(topic, event) {
    if (!topic.workflow_can_act || this.transitionInFlightTopicId) {
      event.preventDefault();
      return;
    }

    this.draggedTopicId = Number(topic.id);
    this.draggedFromPosition = Number(topic.workflow_step_position);
    event.dataTransfer.setData("text/plain", String(topic.id));
    event.dataTransfer.dropEffect = "move";
    event.dataTransfer.effectAllowed = "move";
  }

  @action
  cardDragEnd(topic) {
    this.clearDragState(topic?.id);
  }

  @action
  openKanbanTopic(topic, event) {
    if (
      this.transitionInFlightTopicId ||
      this.draggedTopicId ||
      Number(this.recentlyDraggedTopicId) === Number(topic.id)
    ) {
      event.preventDefault();
      return;
    }

    if (event.metaKey || event.ctrlKey) {
      window.open(topic.workflow_topic_url, "_blank", "noopener,noreferrer");
      return;
    }

    this.router.transitionTo(topic.workflow_topic_url);
  }

  @action
  async openKanbanTopicWithKeyboard(topic, event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.openKanbanTopic(topic, event);
      return;
    }

    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") {
      return;
    }

    event.preventDefault();

    if (!topic.workflow_can_act || this.transitionInFlightTopicId) {
      return;
    }

    const fromPosition = Number(topic.workflow_step_position);
    const direction = event.key === "ArrowRight" ? 1 : -1;
    const targetPosition = this.adjacentStepPosition(fromPosition, direction);
    const topicId = Number(topic.id);

    if (!targetPosition) {
      return;
    }

    const didTransition = await this.transitionTopic(
      topicId,
      fromPosition,
      targetPosition
    );

    if (didTransition) {
      this.focusKanbanCard(topicId);
    }
  }

  @action
  columnDragOver(column, event) {
    if (!this.isColumnLegalDropTarget(column.position)) {
      return;
    }

    event.preventDefault();
    event.dataTransfer.dropEffect =
      Number(column.position) === Number(this.draggedFromPosition)
        ? "none"
        : "move";
  }

  updateTopicTransitionState(topicId, targetPosition) {
    const topicCollections = [
      this.discovery.currentTopicList?.topics,
      this.topicList?.topics,
      this.topicListMetadata?.topics,
      this.topicListMetadata?.topic_list?.topics,
    ];

    topicCollections.forEach((topicCollection) => {
      if (!Array.isArray(topicCollection)) {
        return;
      }

      const topic = topicCollection.find(
        (candidate) => Number(candidate.id) === topicId
      );
      if (!topic) {
        return;
      }

      set(topic, "workflow_step_position", targetPosition);
      set(topic, "workflow_step_name", this.kanbanStepNames[targetPosition]);
      set(topic, "workflow_overdue", false);
    });
  }

  async transitionTopic(topicId, fromPosition, toPosition) {
    if (
      !topicId ||
      !fromPosition ||
      !toPosition ||
      toPosition === fromPosition
    ) {
      return false;
    }

    const optionSlug = this.optionSlugForTransition(fromPosition, toPosition);
    if (!optionSlug) {
      return false;
    }

    this.transitionInFlightTopicId = topicId;

    try {
      await ajax(`/discourse-workflow/act/${topicId}`, {
        type: "POST",
        data: { option: optionSlug },
      });

      this.updateTopicTransitionState(topicId, toPosition);
      return true;
    } catch (error) {
      await this.dialog.alert(extractError(error));
      this.router.refresh();
      return false;
    } finally {
      this.transitionInFlightTopicId = null;
    }
  }

  focusKanbanCard(topicId) {
    if (typeof document === "undefined") {
      return;
    }

    document
      .querySelector(`.workflow-kanban__card[data-topic-id="${topicId}"]`)
      ?.focus();
  }

  @action
  async columnDrop(column, event) {
    event.preventDefault();

    const topicId =
      Number(event.dataTransfer.getData("text/plain")) || this.draggedTopicId;
    const fromPosition = Number(this.draggedFromPosition);
    const toPosition = Number(column.position);

    await this.transitionTopic(topicId, fromPosition, toPosition);
    this.clearDragState(topicId);
  }

  @action
  syncStepPositionFromUrl() {
    const params = this.currentSearchParams;
    this.stepPosition = params.get("workflow_step_position") || "";
    this.workflowView =
      params.get("workflow_view") ||
      (this.isWorkflowChartsRoute ? "chart" : null);

    if (this.isChartView && !this.canUseChartView) {
      const fallback = Object.fromEntries(params.entries());
      delete fallback.workflow_view;
      delete fallback.chart_weeks;
      this.workflowView = null;
      this.navigateWithFilters(fallback);
      return;
    }

    this.syncBodyClass();
  }

  @action
  syncBodyClass() {
    if (typeof document === "undefined") {
      return;
    }

    document.body.classList.toggle("workflow-kanban-view", this.isKanbanView);
    document
      .querySelector("#list-area .contents")
      ?.classList.toggle("workflow-kanban-hide-topics", this.isKanbanView);
    document.body.classList.toggle("workflow-charts-view", this.isChartView);
    document
      .querySelector("#list-area .contents")
      ?.classList.toggle("workflow-charts-hide-topics", this.isChartView);
  }

  <template>
    {{#if this.isWorkflowRoute}}
      <div
        class={{if
          this.isKanbanView
          "discovery-list-container-top-outlet workflow-quick-filters workflow-quick-filters--kanban-active"
          "discovery-list-container-top-outlet workflow-quick-filters"
        }}
        {{didInsert this.initializeFilters}}
        {{didInsert this.syncBodyClass}}
        {{didUpdate this.syncStepPositionFromUrl this.currentLocation}}
      >
        {{#if this.showWorkflowViewSelector}}
          <select
            class="workflow-quick-filters__view-select"
            value={{this.currentWorkflowView}}
            aria-label={{i18n "discourse_workflow.quick_filters.view_label"}}
            {{on "change" this.changeWorkflowView}}
          >
            <option value="list">
              {{i18n "discourse_workflow.quick_filters.list_view"}}
            </option>
            {{#if this.canUseKanbanView}}
              <option value="kanban">
                {{i18n "discourse_workflow.quick_filters.kanban_view"}}
              </option>
            {{/if}}
            {{#if this.showChartViewOption}}
              <option value="chart">
                {{i18n "discourse_workflow.quick_filters.chart_view"}}
              </option>
            {{/if}}
          </select>
        {{/if}}
        {{#if this.isChartView}}
          <select
            class="workflow-quick-filters__chart-weeks-select"
            value={{this.chartWeeksValue}}
            aria-label={{i18n "discourse_workflow.charts.weeks_label"}}
            {{on "change" this.changeChartWeeks}}
          >
            {{#each this.chartWeekOptions as |weeks|}}
              <option value={{weeks}}>
                {{i18n "discourse_workflow.charts.weeks_value" count=weeks}}
              </option>
            {{/each}}
          </select>
        {{/if}}

        {{#unless this.isChartView}}
          <DButton
            class={{if
              this.hasMyCategoriesFilter
              "workflow-quick-filters__my-categories btn-primary"
              "workflow-quick-filters__my-categories btn-default"
            }}
            @label="discourse_workflow.quick_filters.my_categories"
            @action={{this.toggleMyCategories}}
          />
          <DButton
            class={{if
              this.hasOverdueFilter
              "workflow-quick-filters__overdue btn-primary"
              "workflow-quick-filters__overdue btn-default"
            }}
            @label="discourse_workflow.quick_filters.overdue"
            @action={{this.toggleOverdue}}
          />
          <input
            class="workflow-quick-filters__step-input"
            type="number"
            min="1"
            value={{this.stepPosition}}
            placeholder={{i18n
              "discourse_workflow.quick_filters.step_placeholder"
            }}
            {{on "input" this.updateStepPosition}}
          />
          <DButton
            class={{if
              this.hasStepFilter
              "workflow-quick-filters__apply-step btn-primary"
              "workflow-quick-filters__apply-step btn-default"
            }}
            @label="discourse_workflow.quick_filters.apply_step"
            @action={{this.applyStepFilter}}
          />
        {{/unless}}
        <DButton
          class="workflow-quick-filters__clear btn-default"
          @label="discourse_workflow.quick_filters.clear"
          @action={{this.clearFilters}}
        />

        {{#if this.shouldRenderKanbanBoard}}
          <section
            class={{if
              this.isKanbanView
              (if
                this.draggedTopicId
                "workflow-kanban workflow-kanban--active workflow-kanban--dragging"
                "workflow-kanban workflow-kanban--active"
              )
              "workflow-kanban"
            }}
            data-workflow-kanban-view={{if this.isKanbanView "active"}}
          >
            <div class="workflow-kanban__header">
              <h3 class="workflow-kanban__title">
                {{i18n "discourse_workflow.kanban.title"}}
              </h3>
              {{#if this.kanbanWorkflowName}}
                <p class="workflow-kanban__workflow-name">
                  {{i18n
                    "discourse_workflow.kanban.workflow_name"
                    workflow_name=this.kanbanWorkflowName
                  }}
                </p>
              {{/if}}
            </div>

            <div class="workflow-kanban__columns">
              {{#each this.kanbanColumns key="position" as |column|}}
                <section
                  class={{column.column_class}}
                  style={{column.column_style}}
                  data-workflow-step-position={{column.position}}
                  {{on "dragover" (fn this.columnDragOver column)}}
                  {{on "drop" (fn this.columnDrop column)}}
                >
                  <div class="workflow-kanban__column-header">
                    <span class="workflow-kanban__step-position">
                      {{column.position}}
                    </span>
                    <span
                      class="workflow-kanban__step-name"
                    >{{column.name}}</span>
                    <span class="workflow-kanban__topic-count">
                      {{column.topic_count_label}}
                    </span>
                  </div>

                  <div class="workflow-kanban__cards">
                    {{#if column.topics.length}}
                      {{#each column.topics key="id" as |topic|}}
                        <div
                          class={{if
                            topic.workflow_can_act
                            (if
                              topic.is_dragging
                              "workflow-kanban__card workflow-kanban__card--draggable workflow-kanban__card--dragging"
                              (if
                                topic.is_transitioning
                                "workflow-kanban__card workflow-kanban__card--draggable workflow-kanban__card--transitioning"
                                "workflow-kanban__card workflow-kanban__card--draggable"
                              )
                            )
                            "workflow-kanban__card workflow-kanban__card--locked"
                          }}
                          data-topic-id={{topic.id}}
                          draggable={{if
                            topic.workflow_can_act
                            (if topic.is_transitioning false true)
                            false
                          }}
                          role="link"
                          tabindex="0"
                          {{on "dragstart" (fn this.cardDragStart topic)}}
                          {{on "dragend" (fn this.cardDragEnd topic)}}
                          {{on "click" (fn this.openKanbanTopic topic)}}
                          {{on
                            "keydown"
                            (fn this.openKanbanTopicWithKeyboard topic)
                          }}
                        >
                          <span class="workflow-kanban__card-title">
                            {{topic.title}}
                          </span>
                          {{#if this.showKanbanTags}}
                            {{#if topic.tags.length}}
                              {{discourseTags
                                null
                                tags=topic.tags
                                style="box"
                                tagName="span"
                                className="workflow-kanban__tags"
                              }}
                            {{/if}}
                          {{/if}}
                          {{#if topic.workflow_overdue}}
                            <span class="workflow-kanban__card-overdue">
                              {{i18n "discourse_workflow.overdue_indicator"}}
                            </span>
                          {{/if}}
                        </div>
                      {{/each}}
                    {{else}}
                      <p class="workflow-kanban__empty-step">
                        {{i18n "discourse_workflow.kanban.empty_step"}}
                      </p>
                    {{/if}}
                  </div>
                </section>
              {{/each}}
            </div>
          </section>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
