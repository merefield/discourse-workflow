import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import BackButton from "discourse/components/back-button";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DButton from "discourse/components/d-button";
import Textarea from "discourse/components/d-textarea";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n, { i18n } from "discourse-i18n";
import WorkflowStepListEditor from "./workflow-step-list-editor";

export default class WorkflowEditor extends Component {
  @service adminPluginNavManager;
  @service router;
  @service store;
  @service dialog;
  @service toasts;

  @tracked isSaving = false;
  @tracked editingModel = null;
  @tracked showDelete = false;

  @action
  updateModel() {
    this.editingModel = this.args.workflow.workingCopy();
    this.showDelete = !this.args.workflow.isNew && !this.args.workflow.system;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.workflow.workingCopy();

    this.args.workflow.setProperties(this.editingModel);
    try {
      await this.args.workflow.save();
      this.#sortWorkflows();
      this.toasts.success({
        data: { message: i18n("admin.discourse_workflow.workflows.saved") },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.discourse-workflow-workflows",
        this.store.findAll("workflow")
      );
    } catch (e) {
      this.args.workflow.setProperties(backupModel);
      popupAjaxError(e);
    } finally {
      later(() => {
        this.isSaving = false;
      }, 1000);
    }
  }

  @action
  delete() {
    return this.dialog.confirm({
      message: i18n("admin.discourse_workflow.workflows.confirm_delete"),
      didConfirm: () => {
        return this.args.workflow.destroyRecord().then(() => {
          this.router.transitionTo(
            "adminPlugins.show.discourse-workflow-workflows",
            this.store.findAll("workflow")
          );
        });
      },
    });
  }

  @action
  async toggleEnabled() {
    await this.toggleField("enabled");
  }

  async toggleField(field, sortWorkflows) {
    this.args.workflow.set(field, !this.args.workflow[field]);
    this.editingModel.set(field, this.args.workflow[field]);
    if (!this.args.workflow.isNew) {
      try {
        const args = {};
        args[field] = this.args.workflow[field];

        await this.args.workflow.update(args);
        if (sortWorkflows) {
          this.sortWorkflows();
        }
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }

  get showSteps() {
    return this.args.workflow.id > 0;
  }

  validationWarningMessage(warning) {
    const code = warning.code;

    if (code === "duplicate_step_positions") {
      return i18n(
        "admin.discourse_workflow.workflows.validation.duplicate_step_positions",
        {
          positions: (warning.positions || []).join(", "),
        }
      );
    }

    if (code === "orphan_target_steps") {
      return i18n(
        "admin.discourse_workflow.workflows.validation.orphan_target_steps",
        {
          count: (warning.option_ids || []).length,
        }
      );
    }

    if (code === "missing_option_labels") {
      return i18n(
        "admin.discourse_workflow.workflows.validation.missing_option_labels",
        {
          slugs: (warning.slugs || []).join(", "),
        }
      );
    }

    return code;
  }

  #sortWorkflows() {
    const sorted = this.args.workflows.toArray().sort((a, b) => {
      return a.name.localeCompare(b.name);
    });
    this.args.workflows.clear();
    this.args.workflows.setObjects(sorted);
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows/{{@model.id}}"
      @label={{i18n "admin.discourse_workflow.workflows.workflow.short_title"}}
    />
    <BackButton
      @route="adminPlugins.show.discourse-workflow-workflows"
      @label="admin.discourse_workflow.workflows.back"
    />
    {{#if @workflow.name}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.editing.title"
          workflow_name=@workflow.name
        }}</h2>
    {{else}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.new.title"
        }}</h2>
    {{/if}}
    <form
      class="form-horizontal workflow-editor"
      {{didUpdate this.updateModel @model.id}}
      {{didInsert this.updateModel @model.id}}
    >
      {{#if @workflow.validation_warnings.length}}
        <div class="control-group workflow-editor__validation-warnings">
          <label>{{i18n
              "admin.discourse_workflow.workflows.validation.title"
            }}</label>
          <ul>
            {{#each @workflow.validation_warnings as |warning|}}
              <li>{{this.validationWarningMessage warning}}</li>
            {{/each}}
          </ul>
        </div>
      {{/if}}
      <div class="control-group">
        <DToggleSwitch
          class="workflow-editor__enabled"
          @state={{@workflow.enabled}}
          @label="admin.discourse_workflow.workflows.enabled"
          {{on "click" this.toggleEnabled}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t "admin.discourse_workflow.workflows.name"}}</label>
        <Input
          class="workflow-editor__name"
          @type="text"
          @value={{this.editingModel.name}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.description"
          }}</label>
        <Textarea
          class="workflow-editor__description"
          @value={{this.editingModel.description}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.overdue_days"
          }}</label>
        <Input
          class="workflow-editor__overdue-days"
          @type="number"
          min="0"
          @value={{this.editingModel.overdue_days}}
          disabled={{this.editingModel.system}}
        />
        <p>{{i18n "admin.discourse_workflow.workflows.overdue_days_help"}}</p>
      </div>
      {{#if @workflow.id}}
        <div class="control-group">
          <label>{{i18n
              "admin.discourse_workflow.workflows.kanban_compatibility.label"
            }}</label>
          <p>
            {{#if @workflow.kanban_compatible}}
              <span class="workflow-editor__kanban-compatible">
                {{i18n
                  "admin.discourse_workflow.workflows.kanban_compatibility.compatible"
                }}
              </span>
            {{else}}
              <span class="workflow-editor__kanban-incompatible">
                {{i18n
                  "admin.discourse_workflow.workflows.kanban_compatibility.incompatible"
                }}
              </span>
            {{/if}}
          </p>
          <p>{{i18n
              "admin.discourse_workflow.workflows.kanban_compatibility.help"
            }}</p>
        </div>
      {{/if}}
      {{#if this.showSteps}}
        <div class="control-group">
          <WorkflowStepListEditor
            class="workflow-editor__steps"
            @workflow={{@workflow}}
            @disabled={{this.editingModel.system}}
            @onChange={{this.stepsChanged}}
          />
        </div>
      {{/if}}
      <div class="control-group workflow-editor__action_panel">
        <DButton
          class="btn-primary workflow-editor__save"
          @action={{this.save}}
          @disabled={{this.isSaving}}
        >{{I18n.t "admin.discourse_workflow.workflows.save"}}</DButton>
        {{#if this.showDelete}}
          <DButton
            @action={{this.delete}}
            class="btn-danger workflow-editor__delete"
          >
            {{I18n.t "admin.discourse_workflow.workflows.delete"}}
          </DButton>
        {{/if}}
      </div>
    </form>
  </template>
}
