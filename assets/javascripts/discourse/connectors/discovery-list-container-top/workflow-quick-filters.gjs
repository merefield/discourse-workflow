import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";

const STORAGE_KEY = "discourse_workflow_quick_filters";

export default class WorkflowQuickFiltersConnector extends Component {
  @service router;

  @tracked stepPosition = "";

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

    return sanitized;
  }

  get currentLocation() {
    return this.router.currentURL || `${window.location.pathname}${window.location.search}`;
  }

  get currentPathname() {
    return this.currentLocation.split("?")[0];
  }

  get currentSearchParams() {
    const queryString = this.currentLocation.split("?")[1] || "";
    return new URLSearchParams(queryString);
  }

  get isWorkflowRoute() {
    return this.currentPathname.startsWith("/workflow");
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

  @action
  initializeFilters() {
    const params = this.currentSearchParams;
    this.stepPosition = params.get("workflow_step_position") || "";

    if (
      params.has("my_categories") ||
      params.has("overdue") ||
      params.has("overdue_days") ||
      params.has("workflow_step_position")
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
    };
    const currentParams = this.currentSearchParams;
    const unchanged =
      (currentParams.get("my_categories") || null) === queryParams.my_categories &&
      (currentParams.get("overdue") || null) === queryParams.overdue &&
      (currentParams.get("overdue_days") || null) === queryParams.overdue_days &&
      (currentParams.get("workflow_step_position") || null) ===
        queryParams.workflow_step_position;

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
  syncStepPositionFromUrl() {
    this.stepPosition = this.currentSearchParams.get("workflow_step_position") || "";
  }

  <template>
    {{#if this.isWorkflowRoute}}
      <div
        class="discovery-list-container-top-outlet workflow-quick-filters"
        {{didInsert this.initializeFilters}}
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
          placeholder={{i18n "discourse_workflow.quick_filters.step_placeholder"}}
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
        <DButton
          class="workflow-quick-filters__clear btn-default"
          @label="discourse_workflow.quick_filters.clear"
          @action={{this.clearFilters}}
        />
      </div>
    {{/if}}
  </template>
}
