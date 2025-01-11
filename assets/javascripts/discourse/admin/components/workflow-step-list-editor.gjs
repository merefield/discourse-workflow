import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/components/d-page-subheader";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import categoryLink from "discourse/helpers/category-link";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse-common/utils/decorators";
import { i18n } from "discourse-i18n";
import WorkflowLinkButton from "./workflow-link-button";
import WorkflowStepEditor from "./workflow-step-editor";

export default class WorkflowStepsListEditor extends Component {
  @service adminPluginNavManager;
  @service store;
  @tracked currentWorkflowStep = this.args.currentWorkflowStep;
  @tracked workflowSteps = [];
  @tracked workflowStepsPresent = false;

  get newStep() {
    return this.store.createRecord("workflow-step", {
      workflow_id: this.args.workflow.id,
    });
  }

  @action
  async toggleAiEnabled(step) {
    const oldValue = step.ai_enabled;
    const newValue = !oldValue;

    try {
      step.set("ai_enabled", newValue);
      await step.save();
    } catch (err) {
      step.set("ai_enabled", oldValue);
      popupAjaxError(err);
    }
  }

  @bind
  loadSteps() {
    if (!this.args.currentWorkflowStep && this.args.workflow.id) {
      this.store
        .find("workflow-step", { workflow_id: this.args.workflow.id })
        .then((steps) => {
          this.workflowSteps = steps.content;
          this.workflowStepsPresent = steps.content.length > 0 ? true : false;
        });
    }
  }

  @action
  moveUp(step) {
    const steps = this.workflowSteps;
    if (step.position > 1) {
      const filteredSteps = steps.filter((s) => s.position < step.position);
      const previousStep =
        filteredSteps.length > 1
          ? filteredSteps.reduce((prev, curr) =>
              prev.position > curr.position ? prev : curr
            )
          : filteredSteps[0] || null;
      const previousPosition = previousStep
        ? previousStep.position
        : step.position - 1;
      if (previousStep) {
        try {
          previousStep.set("position", step.position);
          previousStep.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        step.set("position", previousPosition);
        step.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowSteps = this.workflowSteps.sort(
      (a, b) => a.position - b.position
    );
  }

  @action
  moveDown(step) {
    const steps = this.workflowSteps;
    if (step.position < steps.length) {
      const filteredSteps = steps.filter((s) => s.position > step.position);
      const nextStep =
        filteredSteps.length > 1
          ? filteredSteps.reduce((prev, curr) =>
              prev.position < curr.position ? prev : curr
            )
          : filteredSteps[0] || null;
      const nextPosition = nextStep ? nextStep.position : step.position + 1;
      if (nextStep) {
        try {
          nextStep.set("position", step.position);
          nextStep.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        step.set("position", nextPosition);
        step.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowSteps = this.workflowSteps.sort(
      (a, b) => a.position - b.position
    );
  }
  /* eslint-disable */
  isfirstStep(step, length) {
    return step.position === 1;
  }
  /* eslint-enable */

  islastStep(step, length) {
    return step.position === length;
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows/steps"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    />
    <section
      class="workflow-step-list-editor__current admin-detail pull-left"
      {{didInsert this.loadSteps}}
    >
      {{#if this.currentWorkflowStep}}
        <WorkflowStepEditor
          @currentWorkflowStep={{this.currentWorkflowStep}}
          @workflow={{@workflow}}
          @workflowSteps={{@workflowSteps}}
        />
      {{else}}
        <DPageSubheader
          @titleLabel={{i18n "admin.discourse_workflow.workflows.steps.title"}}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        />

        {{#if this.workflowStepsPresent}}
          <table class="content-list workflow-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.position"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.name"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.category"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.description"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.ai_enabled"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.ai_prompt"
                  }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.workflowSteps as |step|}}
                <tr
                  data-workflow-step-id={{step.position}}
                  class={{concatClass
                    "workflow-step-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__position">
                      <strong>
                        {{step.position}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__name">
                      <strong>
                        {{step.name}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__category_name">
                      {{categoryLink step.category}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__description">
                      {{step.description}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <DToggleSwitch
                      class="workflow-editor__ai_enabled"
                      @state={{step.ai_enabled}}
                      @label="admin.discourse_workflow.workflows.enabled"
                      {{on "click" (fn this.toggleAiEnabled step)}}
                    />
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__ai_prompt">
                      {{step.ai_prompt}}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    {{#unless
                      (this.isfirstStep step this.workflowSteps.length)
                    }}
                      <DButton
                        class="workflow-editor__ai_enabled"
                        @icon="arrow-up"
                        @title="admin.discourse_workflow.workflows.steps.move_up"
                        {{on "click" (fn this.moveUp step)}}
                      />
                    {{/unless}}
                    {{#unless (this.islastStep step this.workflowSteps.length)}}
                      <DButton
                        class="workflow-editor__ai_enabled"
                        @icon="arrow-down"
                        @title="admin.discourse_workflow.workflows.steps.move_down"
                        {{on "click" (fn this.moveDown step)}}
                      />
                    {{/unless}}
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.steps.edit"
                      @models={{array @workflow.id step}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}}
                    </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{/if}}
        <WorkflowLinkButton
          @route="adminPlugins.show.discourse-workflow-workflows.steps.new"
          @label="admin.discourse_workflow.workflows.steps.new"
          @model={{@workflow}}
        />
      {{/if}}
    </section>
  </template>
}
