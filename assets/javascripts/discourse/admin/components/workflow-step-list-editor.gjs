import Component from "@glimmer/component";
import { fn, array, hash } from "@ember/helper";
import { bind } from "discourse-common/utils/decorators";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { cached, tracked } from "@glimmer/tracking";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DPageSubheader from "discourse/components/d-page-subheader";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import i18n from "discourse-common/helpers/i18n";
import AdminConfigAreaEmptyList from "admin/components/admin-config-area-empty-list";
import WorkflowStepEditor from "./workflow-step-editor";
import categoryLink from "discourse/helpers/category-link";
import DButton from "discourse/components/d-button";
import I18n from "discourse-i18n";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";

export default class WorkflowStepsListEditor extends Component {
  @service adminPluginNavManager;
  @service store;
  @tracked currentWorkflowStep = this.args.currentWorkflowStep;
  // @tracked showStepForm = false;
  @tracked workflowSteps = [];
  @tracked workflowStepsPresent = false;

  // @action
  // async toggleEnabled(workflow) {
  //   const oldValue = workflow.enabled;
  //   const newValue = !oldValue;

  //   try {
  //     workflow.set("enabled", newValue);
  //     await workflow.save();
  //   } catch (err) {
  //     workflow.set("enabled", oldValue);
  //     popupAjaxError(err);
  //   }
  // }

  @action
  newStep() {
    // this.showStepForm = true;
    this.currentWorkflowStep = this.store.createRecord("workflow-step", {
      workflow_id: this.args.workflow.id,
    });
  }

  // get workflowStepRecord() {
  //   debugger;
  //   if (this.args.action === "edit") {
  //     return this.args.currentWorkflowStep;
  //   } else {
  //     return this.currentWorkflowStep 
  //   }
  //   // return this.store.peekRecord("workflow-step", this.currentWorkflowStep.id);
  // }

  @bind
  loadSteps() {
    if (!this.args.currentWorkflowStep) {
      this.store.findAll("workflow-step", { workflow_id: this.args.workflow.id }).then((steps) => {
        this.workflowSteps = steps.content;
        this.workflowStepsPresent = steps.content.length > 0 ? true : false;
      });
    }
  }

  // workflowSteps() {
  //   const steps = this.store.findAll("workflow-step", { workflow_id: this.args.workflow.id });
  //   debugger;
  //   console.log(steps);
  //   return steps;
  // }

  <template>
    {{!-- <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    /> --}}
    <section class="workflow-step-list-editor__current admin-detail pull-left"
    {{didInsert this.loadSteps}}>
      {{#if this.currentWorkflowStep}}
        <WorkflowStepEditor @currentWorkflowStep={{this.currentWorkflowStep}} @workflow={{@workflow}}/>
      {{else}}
        <DPageSubheader
          @titleLabel={{i18n "admin.discourse_workflow.workflows.steps.title"}}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        >
          {{!-- <:actions as |actions|>
            <actions.Primary
              @label="discourse_workflow.workflows.new"
              @route="adminPlugins.show.discourse-workflows.new"
              @icon="plus"
              class="workflow-step-list-editor__new-button"
            />
          </:actions> --}}
        </DPageSubheader>

        {{#if this.workflowStepsPresent}}
          <table class="content-list workflow-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.workflow_step_id"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.name"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.category"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.description"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.step_type"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.workflowSteps as |step|}}
                <tr
                  data-workflow-step-id={{step.workflow_step_id}}
                  class={{concatClass
                    "workflow-step-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-list__workflow_step_id">
                      <strong>
                        {{step.workflow_step_id}}
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
                    <div class="workflow-step-list__step_type">
                      {{step.step_type}}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.steps.edit"
                      @model={{step}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}} </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <DButton
            class="btn-primary workflow-editor__save"
            @action={{this.newStep}}
            @disabled={{this.isSaving}}
          >{{I18n.t "admin.discourse_workflow.workflows.steps.new"}}</DButton>
        {{/if}}
      {{/if}}
    </section>
  </template>
}