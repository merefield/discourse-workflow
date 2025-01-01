import Component from "@glimmer/component";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { cached, tracked } from "@glimmer/tracking";
import { later } from "@ember/runloop";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import BackButton from "discourse/components/back-button";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { Input } from "@ember/component";
import Textarea from "discourse/components/d-textarea";
import CategoryChooser from "select-kit/components/category-chooser";
import DButton from "discourse/components/d-button";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DPageSubheader from "discourse/components/d-page-subheader";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import i18n from "discourse-common/helpers/i18n";
import AdminConfigAreaEmptyList from "admin/components/admin-config-area-empty-list";
import WorkflowBackButton from "./workflow-back-button";
import I18n from "discourse-i18n";

export default class WorkflowStepOptionEditor extends Component {
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
    this.editingModel = this.args.currentWorkflowStepOption.workingCopy();
    this.showDelete = !this.args.currentWorkflowStepOption.isNew && !this.args.currentWorkflowStepOption.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  async save() {
    const isNew = this.args.currentWorkflowStepOption.isNew;
    this.isSaving = true;

    const backupModel = this.args.currentWorkflowStepOption.workingCopy();

    this.args.currentWorkflowStepOption.setProperties(this.editingModel);
    try {
      await this.args.currentWorkflowStepOption.save();
      this.isSaving = false;
      // this.#sortPersonas();
      // if (isNew) {
      //   this.args.workflow_steps.addObject(this.args.currentWorkflowStepOption);
      //   this.router.transitionTo(
      //     "adminPlugins.show.discourse-workflow-workflows.steps.edit",
      //     this.args.currentWorkflowStepOption
      //   );
      // } else {
        this.toasts.success({
          data: { message: I18n.t("admin.discourse_workflow.workflows.steps.saved") },
          duration: 2000,
        });
      // }
    } catch (e) {
      this.args.currentWorkflowStepOption.setProperties(backupModel);
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
      message: I18n.t("admin.discourse_workflow.workflows.steps.confirm_delete"),
      didConfirm: () => {
        return this.args.currentWorkflowStepOption.destroyRecord().then(() => {
          this.toasts.success({
            data: { message: I18n.t("admin.discourse_workflow.workflows.steps.deleted") },
            duration: 2000,
          });

          // this.args.workflowSteps.removeObject(this.args.currentWorkflowStepOption);
          this.router.transitionTo(
            "adminPlugins.show.discourse-workflow-workflows.edit",
            this.args.currentWorkflowStepOption.workflow_id
          );
        });
      },
    });
  }

  <template>
    <WorkflowBackButton
      @route="adminPlugins.show.discourse-workflow-workflows.steps.edit"
      @model={{@currentWorkflowStepOption.position}}
    />
    <form
      class="form-horizontal workflow-step-editor"
      {{didUpdate this.updateModel @currentWorkflowStepOption.id}}
      {{didInsert this.updateModel @currentWorkflowStepOption.id}}
    >
      {{!-- <div class="control-group">
        <DToggleSwitch
          class="workflow-editor__enabled"
          @state={{@model.enabled}}
          @label="admin.discourse_workflow.workflows.enabled"
          {{on "click" this.toggleEnabled}}
        />
      </div> --}}
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
      <label>{{I18n.t "admin.discourse_workflow.workflows.steps.category"}}</label>
        <CategoryChooser
          @value={{this.editingModel.category_id}}
          @onChangeCategory={{fn (mut this.editingModel.category_id)}}
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
        {{!-- <WorkflowStepListEditor
          class="workflow-editor__steps"
          @id={{this.model.id}}
          @disabled={{this.editingModel.system}}
          @workflowSteps={{@workflow.workflow_steps}}
          @onChange={{this.stepsChanged}}
        /> --}}
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