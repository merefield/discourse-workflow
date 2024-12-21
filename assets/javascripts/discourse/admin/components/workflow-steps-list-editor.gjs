import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
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

export default class WorkflowStepsListEditor extends Component {
  @service adminPluginNavManager;

  @action
  async toggleEnabled(workflow) {
    const oldValue = workflow.enabled;
    const newValue = !oldValue;

    try {
      workflow.set("enabled", newValue);
      await workflow.save();
    } catch (err) {
      workflow.set("enabled", oldValue);
      popupAjaxError(err);
    }
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    />
    <section class="workflow-steps-list-editor__current admin-detail pull-left">
      {{#if @currentWorkflowStep}}
        <WorkflowStepEditor @model={{@currentWorkflowStep}} @workflowsSteps={{@workflowSteps}} @workflow={{@workflow}}/>
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
              class="workflow-list-editor__new-button"
            />
          </:actions> --}}
        </DPageSubheader>

        {{#if @workflowSteps}}
          <table class="content-list workflow-steps-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "discourse_workflow.workflows.name"}}</th>
                <th>{{i18n "discourse_workflow.workflows.enabled"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @workflows as |workflow|}}
                <tr
                  data-workflow-id={{workflow.id}}
                  class={{concatClass
                    "workflow-list__row d-admin-row__content"
                    (if workflow.priority "priority")
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-list__name-with-description">
                      <div class="workflow-list__name">
                        <strong>
                          {{workflow.name}}
                        </strong>
                      </div>
                      <div class="workflow-list__description">
                        {{workflow.description}}
                      </div>
                    </div>
                  </td>
                  <td class="d-admin-row__detail">
                    <DToggleSwitch
                      @state={{workflow.enabled}}
                      {{on "click" (fn this.toggleEnabled workflow)}}
                    />
                  </td>
                  <td class="d-admin-row__controls">
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflows.edit"
                      @model={{workflow}}
                      class="btn btn-text btn-small"
                    >{{i18n "discourse_workflow.workflows.edit"}} </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <AdminConfigAreaEmptyList
            @ctaLabel="admin.discourse_workflow.workflows.steps.new"
            @ctaRoute="adminPlugins.show.discourse-workflows.new"
            @ctaClass="workflow-steps-list-editor__empty-new-button"
            @emptyLabel="admin.discourse_workflow.workflows.steps.no_steps"
          />
        {{/if}}
      {{/if}}
    </section>
  </template>
}