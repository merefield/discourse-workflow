import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { LinkTo } from "@ember/routing";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import BackButton from "discourse/components/back-button";
import DButton from "discourse/components/d-button";
import Textarea from "discourse/components/d-textarea";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import Avatar from "discourse/helpers/bound-avatar-template";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Group from "discourse/models/group";
import I18n from "discourse-i18n";
import i18n from "discourse-common/helpers/i18n";
import AdminUser from "admin/models/admin-user";
import ComboBox from "select-kit/components/combo-box";
import GroupChooser from "select-kit/components/group-chooser";
import DTooltip from "float-kit/components/d-tooltip";
// import AiLlmSelector from "./ai-llm-selector";
// import AiPersonaToolOptions from "./workflow-tool-options";
// import AiToolSelector from "./ai-tool-selector";
import WorkflowStepListEditor from "./workflow-step-list-editor";

export default class WorkflowEditor extends Component {
  @service adminPluginNavManager;
  @service router;
  @service store;
  @service dialog;
  @service toasts;
  @service siteSettings;

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
    const isNew = this.args.workflow.isNew;
    this.isSaving = true;

    const backupModel = this.args.workflow.workingCopy();

    this.args.workflow.setProperties(this.editingModel);
    try {
      await this.args.workflow.save();
      this.#sortWorkflows();
      // if (isNew && this.args.workflow.rag_uploads.length === 0) {
      //   this.args.personas.addObject(this.args.workflow);
      //   this.router.transitionTo(
      //     "adminPlugins.show.discourse-ai-personas.edit",
      //     this.args.workflow
      //   );
      // } else {
        this.toasts.success({
          data: { message: I18n.t("admin.discourse_workflow.workflows.saved") },
          duration: 2000,
        });
      // }
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
      message: I18n.t("admin.discourse_workflow.workflows.confirm_delete"),
      didConfirm: () => {
        return this.args.workflow.destroyRecord().then(() => {
          this.args.workflow_steps.removeObject(this.args.workflow);
          this.router.transitionTo(
            "adminPlugins.show.discourse-workflows.index"
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
    <form
      class="form-horizontal workflow-editor"
      {{didUpdate this.updateModel @model.id}}
      {{didInsert this.updateModel @model.id}}
    >
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
        <label>{{I18n.t "admin.discourse_workflow.workflows.description"}}</label>
        <Textarea
          class="workflow-editor__description"
          @value={{this.editingModel.description}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        {{!-- <label>{{I18n.t "admin.discourse_workflow.workflows.steps"}}</label> --}}
        <WorkflowStepListEditor
          class="workflow-editor__steps"
          @workflow={{@workflow}}
          @disabled={{this.editingModel.system}}
          @onChange={{this.stepsChanged}}
        />
      </div>
      {{!-- {{#unless this.editingModel.system}}
        <AiPersonaToolOptions
          @persona={{this.editingModel}}
          @tools={{this.selectedToolNames}}
          @allTools={{@personas.resultSetMeta.tools}}
        />
      {{/unless}} --}}
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