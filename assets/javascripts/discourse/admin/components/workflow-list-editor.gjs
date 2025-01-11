import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from 'discourse-i18n';
import AdminConfigAreaEmptyList from "admin/components/admin-config-area-empty-list";
import WorkflowEditor from "./workflow-editor";

export default class WorkflowListEditor extends Component {
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
      @label={{i18n "admin.discourse_workflow.workflows.short_title"}}
    />
    <section class="workflow-list-editor__current admin-detail pull-left">
      {{#if @currentWorkflow}}
        <WorkflowEditor
          @workflow={{@currentWorkflow}}
          @workflows={{@workflows}}
        />
      {{else}}
        {{#if @workflows}}
          <table class="content-list workflow-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "admin.discourse_workflow.workflows.enabled"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.name"}}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.description"
                  }}</th>
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
                  <td class="d-admin-row__detail">
                    <DToggleSwitch
                      @state={{workflow.enabled}}
                      {{on "click" (fn this.toggleEnabled workflow)}}
                    />
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-list__name">
                      <strong>
                        {{workflow.name}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-list__description">
                      {{workflow.description}}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.edit"
                      @model={{workflow}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}}
                    </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <AdminConfigAreaEmptyList
            @ctaLabel="discourse_workflow.workflows.new"
            @ctaRoute="adminPlugins.show.discourse-workflows.new"
            @ctaClass="workflow-list-editor__empty-new-button"
            @emptyLabel="discourse_workflow.workflows.no_workflows"
          />
        {{/if}}
      {{/if}}
    </section>
  </template>
}
