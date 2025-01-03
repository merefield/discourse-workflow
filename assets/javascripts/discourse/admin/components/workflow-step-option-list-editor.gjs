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
import WorkflowStepOptionEditor from "./workflow-step-option-editor";

export default class WorkflowStepOptionsListEditor extends Component {
  // @service adminPluginNavManager;
  @service store;
  @tracked currentWorkflowStepOption = this.args.currentWorkflowStepOption;
  @tracked workflowStepOptions = [];
  @tracked workflowStepOptionsPresent = false;


  get newStepOption() {
    return this.store.createRecord("workflow-step-option", {
       workflow_step_id: this.args.workflowStep.id,
   });
  }

  @bind
  loadStepOptions() {
    if (!this.args.currentWorkflowStepOption && this.args.workflowStep.id) {
      this.store.find("workflow-step-option", { workflow_id: this.args.workflowStep.workflow_id, workflow_step_id: this.args.workflowStep.id }).then((options) => {
        this.workflowStepOptions = options.content;
        this.workflowStepOptionsPresent = options.content.length > 0 ? true : false;
      });
    }
  }

  localizedStepOptionName(stepOption) {
    return i18n(`admin.discourse_workflow.workflows.steps.options.actions.${stepOption.workflow_option.slug}`);
  }

  convertStepIdToPosition(workflowSteps, stepOption) {
    if (!workflowSteps) {
      return;
    }
    return workflowSteps.find((step) => step.id === stepOption.target_step_id)?.position;
  }

  @action
  moveUp(option) {
    const options = this.workflowStepOptions;
    const index = options.indexOf(option);
    if (option.position > 1) {
      const filteredOptions = options.filter((s) => s.position < option.position);
      const previousOption = filteredOptions.length > 1
        ? filteredOptions.reduce((prev, curr) => (prev.position > curr.position ? prev : curr))
        : filteredOptions[0] || null;
      const previousPosition = previousOption ? previousOption.position : option.position - 1;
      if (previousOption) {
        try {
          previousOption.set("position", option.position);
          previousOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", previousPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowStepOptions = this.workflowStepOptions.sort((a, b) => a.position - b.position);
  }

  @action
  moveDown(option) {
    const options = this.workflowStepOptions;
    const index = options.indexOf(option);
    if (option.position < options.length) {
      const filteredOptions = options.filter((s) => s.position > option.position);
      const nextOption = filteredOptions.length > 1
        ? filteredOptions.reduce((prev, curr) => (prev.position < curr.position ? prev : curr))
        : filteredOptions[0] || null;
      const nextPosition = nextOption ? nextOption.position : option.position + 1;
      if (nextOption) {
        try {
          nextOption.set("position", option.position);
          nextOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", nextPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowStepOptions = this.workflowStepOptions.sort((a, b) => a.position - b.position);
  }

  isfirstOption(option, length) {
    return option.position === 1;
  }

  islastOption(option, length) {
    return option.position === length;
  }


  <template>
    {{!-- <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows/steps"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    /> --}}
    <section class="workflow-step-list-editor__current admin-detail pull-left"
    {{didInsert this.loadStepOptions}}>
      {{#if this.currentWorkflowStepOption}}
        <WorkflowStepOptionEditor
          @currentWorkflowStepOption={{this.currentWorkflowStepOption}}
          @workflowStep={{@workflowStep}}
          @workflowSteps={{@workflowSteps}}
          @workflowOptions={{@workflowOptions}}
        />
      {{else}}
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

        {{#if this.workflowStepOptionsPresent}}
          <table class="content-list workflow-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.position"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.name"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.steps.options.target_position"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.workflowStepOptions as |stepOption|}}
                <tr
                  data-workflow-step-option-id={{stepOption.workflow_step_option_id}}
                  class={{concatClass
                    "workflow-step-option-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__position">
                      {{stepOption.position}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__name">
                      <strong>
                        {{this.localizedStepOptionName stepOption}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__target_position">
                      <strong>
                        {{log this.args.workflowSteps}}
                        {{this.convertStepIdToPosition this.args.workflowSteps stepOption}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__actions">
                      this will have actions
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    {{#unless (this.isfirstOption stepOption this.workflowStepOptions.length)}}
                      <DButton
                        class="workflow-step-option-list-editor__up_arrow"
                        @icon="arrow-up"
                        @title="admin.discourse_workflow.workflows.options.move_up"
                        {{on "click" (fn this.moveUp stepOption)}}
                      />
                    {{/unless}}
                    {{#unless (this.islastOption stepOption this.workflowStepOptions.length)}}
                      <DButton
                        class="workflow-step-option-list-editor__down_arrow"
                        @icon="arrow-down"
                        @title="admin.discourse_workflow.workflows.options.move_down"
                        {{on "click" (fn this.moveDown stepOption)}}
                      />
                    {{/unless}}
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.steps.options.edit"
                      @models={{array @workflowStep.workflow_id @workflowStep.id stepOption}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}} </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{/if}}
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

      {{/if}}
    </section>
  </template>
}