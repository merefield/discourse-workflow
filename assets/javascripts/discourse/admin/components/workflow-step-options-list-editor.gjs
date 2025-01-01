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
import WorkflowLinkButton from "./workflow-link-button";
import WorkflowDeepLinkButton from "./workflow-deep-link-button";

export default class WorkflowStepOptionsListEditor extends Component {
  // @service adminPluginNavManager;
  @service store;
  @tracked currentWorkflowStep = this.args.currentWorkflowStep;
  @tracked workflowSteps = [];
  @tracked workflowStepsPresent = false;


  get newStep() {
    return this.store.createRecord("workflow-step", {
       workflow_id: this.args.workflow.id,
   });
  }

  @bind
  loadSteps() {
    if (!this.args.currentWorkflowStep && this.args.workflow.id) {
      this.store.find("workflow-step", { workflow_id: this.args.workflow.id }).then((steps) => {
        this.workflowSteps = steps.content;
        this.workflowStepsPresent = steps.content.length > 0 ? true : false;
      });
    }
  }

  localizedStepOptionName(stepOption) {
    return i18n(`admin.discourse_workflow.workflows.steps.options.${stepOption.slug}`);
  }

  <template>

    asdflasdkjflaksdfjlskdjf
    {{!-- <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows/steps"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    /> --}}
    <section class="workflow-step-list-editor__current admin-detail pull-left">
    {{!-- {{didInsert this.loadSteps}}> --}}
      {{!-- {{#if this.currentWorkflowStep}}
        <WorkflowStepEditor @currentWorkflowStep={{this.currentWorkflowStep}} @workflow={{@workflow}}/>
      {{else}} --}}
        <DPageSubheader
          @titleLabel={{i18n "admin.discourse_workflow.workflows.steps.options.title"}}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        >
          {{!-- <:actions as |actions|>
            <actions.Primary
              @label="admin.discourse_workflow.workflows.steps.new"
              @route="adminPlugins.show.discourse-workflow-workflows.steps.new"
              @models={{array @workflow.id}}
              @icon="plus"
              class="workflow-step-list-editor__new-button"
            />
          </:actions> --}}
        </DPageSubheader>

        {{!-- {{#if this.workflowStepsPresent}} --}}
          <table class="content-list workflow-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.workflow_step_option_id"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.name"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.target_position"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.actions"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @workflowStepOptions as |stepOption|}}
                <tr
                  data-workflow-step-option-id={{stepOption.workflow_step_option_id}}
                  class={{concatClass
                    "workflow-step-option-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__workflow_step_option_id">
                      {{categoryLink stepOption.category}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__name">
                      <strong>
                        {{this.localizedStepOptionName stepOption.slug}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__target_position">
                      <strong>
                        {{stepOption.target_position}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__actions">
                      this will have actions
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.steps.options.edit"
                      @models={{array @workflowStep.id stepOption}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}} </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
          {{!-- {{/if}} --}}
          <WorkflowLinkButton
            @route="adminPlugins.show.discourse-workflow-workflows.steps.options.new"
            @label="admin.discourse_workflow.workflows.steps.options.new"
            @model={{@workflowStep}}
            {{!-- @workflow_id={{@workflow.id}} --}}
          />
          {{!-- <LinkTo
            @label="admin.discourse_workflow.workflows.steps.new"
            @route="adminPlugins.show.discourse-workflow-workflows.steps.new"
            @model={{@workflow.id}}
            @icon="plus"
            class="workflow-step-list-editor__new-button"
          /> --}}
          {{!-- <WorkflowDeepLinkButton
            @route="adminPlugins.show.discourse-workflow-workflows.steps.new"
            @label="admin.discourse_workflow.workflows.steps.new"
            @models={{array @workflow.id ""}}
            @workflow_id={{@workflow.id}}
          /> --}}
          {{!-- <DButton
            class="btn-primary workflow-editor__save"
            @action={{this.newStep}}
            @disabled={{this.isSaving}}
          >{{I18n.t "admin.discourse_workflow.workflows.steps.new"}}</DButton> --}}

      {{!-- {{/if}} --}}
    </section>
  </template>
}