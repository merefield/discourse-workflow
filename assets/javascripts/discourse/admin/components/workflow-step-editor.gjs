import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import Textarea from "discourse/components/d-textarea";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n, { i18n } from "discourse-i18n";
import CategoryChooser from "select-kit/components/category-chooser";
import not from "truth-helpers/helpers/not";
import WorkflowBackButton from "./workflow-back-button";
import WorkflowStepOptionListEditor from "./workflow-step-option-list-editor";

export default class WorkflowStepEditor extends Component {
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
    this.editingModel = this.args.currentWorkflowStep.workingCopy();
    this.showDelete =
      !this.args.currentWorkflowStep.isNew &&
      !this.args.currentWorkflowStep.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.currentWorkflowStep.workingCopy();
    this.args.currentWorkflowStep.setProperties(this.editingModel);
    try {
      await this.args.currentWorkflowStep.save();
      this.isSaving = false;
      this.toasts.success({
        data: {
          message: i18n("admin.discourse_workflow.workflows.steps.saved"),
        },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.discourse-workflow-workflows.edit",
        this.args.currentWorkflowStep.workflow_id,
        { queryParams: { refresh: true } }
      );
    } catch (e) {
      this.args.currentWorkflowStep.setProperties(backupModel);
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
      message: i18n("admin.discourse_workflow.workflows.steps.confirm_delete"),
      didConfirm: () => {
        return this.args.currentWorkflowStep.destroyRecord().then(() => {
          this.toasts.success({
            data: {
              message: i18n("admin.discourse_workflow.workflows.steps.deleted"),
            },
            duration: 2000,
          });

          // this.args.currentWorkflowSteps.removeObject(this.args.currentWorkflowStep);
          this.router.transitionTo(
            "adminPlugins.show.discourse-workflow-workflows.edit",
            this.args.currentWorkflowStep.workflow_id,
            { queryParams: { refresh: true } }
          );
        });
      },
    });
  }

  @action
  async toggleAiEnabled() {
    await this.toggleField("ai_enabled");
  }

  async toggleField(field, sortWorkflowSteps) {
    this.args.currentWorkflowStep.set(
      field,
      !this.args.currentWorkflowStep[field]
    );
    this.editingModel.set(field, this.args.currentWorkflowStep[field]);
    if (!this.args.currentWorkflowStep.isNew) {
      try {
        const args = {};
        args[field] = this.args.currentWorkflowStep[field];

        await this.args.currentWorkflowStep.update(args);
        if (sortWorkflowSteps) {
          this.sortWorkflowSteps();
        }
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }

  get showStepOptions() {
    return this.args.currentWorkflowStep.id > 0;
  }

  <template>
    <WorkflowBackButton
      @route="adminPlugins.show.discourse-workflow-workflows.edit"
      @model={{@currentWorkflowStep.workflow_id}}
    />
    {{#if @currentWorkflowStep.id}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.editing.title"
          workflow_step_name=this.editingModel.name
        }}</h2>
    {{else}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.new.title"
        }}</h2>
    {{/if}}
    <form
      class="form-horizontal workflow-step-editor"
      {{didUpdate this.updateModel @currentWorkflowStep.id}}
      {{didInsert this.updateModel @currentWorkflowStep.id}}
    >
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
            "admin.discourse_workflow.workflows.steps.category"
          }}</label>
        <CategoryChooser
          @value={{this.editingModel.category_id}}
          @onChangeCategory={{fn (mut this.editingModel.category_id)}}
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
        <DToggleSwitch
          class="workflow-editor__enabled"
          @state={{this.editingModel.ai_enabled}}
          @label="admin.discourse_workflow.workflows.steps.ai_enabled"
          {{on "click" this.toggleAiEnabled}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.steps.ai_prompt"
          }}</label>
        <Textarea
          class="workflow-editor__ai_prompt"
          @value={{this.editingModel.ai_prompt}}
          disabled={{not this.editingModel.ai_enabled}}
        />
      </div>
      {{#if this.showStepOptions}}
        <div class="control-group">
          <WorkflowStepOptionListEditor
            class="workflow-editor__steps_options"
            @workflowStep={{@currentWorkflowStep}}
            @workflowSteps={{@workflowSteps}}
            @disabled={{this.editingModel.system}}
            @onChange={{this.stepOptionsChanged}}
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
