import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action, get, set } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const STORAGE_KEY = "discourse_workflow_quick_filters";

export default class WorkflowQuickFiltersConnector extends Component {
  @service discovery;
  @service router;

  @tracked stepPosition = "";
  @tracked workflowView = null;
  @tracked draggedTopicId = null;
  @tracked draggedFromPosition = null;
  @tracked transitionInFlightTopicId = null;
  @tracked recentlyDraggedTopicId = null;

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

  willDestroy(...args) {
    super.willDestroy(...args);

    if (typeof document !== "undefined") {
      document.body.classList.remove("workflow-kanban-view");
    }
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

    if (filters?.workflow_view === "kanban") {
      sanitized.workflow_view = "kanban";
    }

    return sanitized;
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

  get canUseKanbanView() {
    try {
      return this.topicListMetadata?.workflow_kanban_compatible === true;
    } catch {
      return false;
    }
  }

  get showKanbanToggle() {
    return this.isKanbanView || this.canUseKanbanView;
  }

  get workflowViewLabel() {
    return this.isKanbanView
      ? "discourse_workflow.quick_filters.list_view"
      : "discourse_workflow.quick_filters.kanban_view";
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

  get kanbanColumns() {
    const topics = (() => {
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
    })();

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
    this.workflowView = params.get("workflow_view") || null;

    if (
      params.has("my_categories") ||
      params.has("overdue") ||
      params.has("overdue_days") ||
      params.has("workflow_step_position") ||
      params.has("workflow_view")
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
        queryParams.workflow_view;

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
  toggleWorkflowView() {
    const params = new URLSearchParams(this.currentSearchParams.toString());

    if (this.isKanbanView) {
      params.delete("workflow_view");
      this.workflowView = null;
    } else {
      params.set("workflow_view", "kanban");
      this.workflowView = "kanban";
    }

    this.syncBodyClass();
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
  openKanbanTopicWithKeyboard(topic, event) {
    if (event.key !== "Enter" && event.key !== " ") {
      return;
    }

    event.preventDefault();
    this.openKanbanTopic(topic, event);
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

  @action
  async columnDrop(column, event) {
    event.preventDefault();

    const topicId =
      Number(event.dataTransfer.getData("text/plain")) || this.draggedTopicId;
    const fromPosition = Number(this.draggedFromPosition);
    const toPosition = Number(column.position);

    if (!topicId || !fromPosition || !toPosition) {
      this.clearDragState(topicId);
      return;
    }

    if (toPosition === fromPosition) {
      this.clearDragState(topicId);
      return;
    }

    const optionSlug = this.optionSlugForTransition(fromPosition, toPosition);
    if (!optionSlug) {
      this.clearDragState(topicId);
      return;
    }

    this.transitionInFlightTopicId = topicId;

    try {
      await ajax(`/discourse-workflow/act/${topicId}`, {
        type: "POST",
        data: { option: optionSlug },
      });

      this.updateTopicTransitionState(topicId, toPosition);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.transitionInFlightTopicId = null;
      this.clearDragState(topicId);
    }
  }

  @action
  syncStepPositionFromUrl() {
    const params = this.currentSearchParams;
    this.stepPosition = params.get("workflow_step_position") || "";
    this.workflowView = params.get("workflow_view") || null;
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
        {{#if this.showKanbanToggle}}
          <DButton
            class={{if
              this.isKanbanView
              "workflow-quick-filters__workflow-view btn-primary"
              "workflow-quick-filters__workflow-view btn-default"
            }}
            @label={{this.workflowViewLabel}}
            @action={{this.toggleWorkflowView}}
          />
        {{/if}}
        <DButton
          class="workflow-quick-filters__clear btn-default"
          @label="discourse_workflow.quick_filters.clear"
          @action={{this.clearFilters}}
        />

        {{#if this.showKanbanToggle}}
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
