import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n, { i18n } from "discourse-i18n";
import DropdownSelectBox from "select-kit/components/dropdown-select-box";
import WorkflowBackButton from "./workflow-back-button";

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
    this.showDelete =
      !this.args.currentWorkflowStepOption.isNew &&
      !this.args.currentWorkflowStepOption.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.currentWorkflowStepOption.workingCopy();

    this.args.currentWorkflowStepOption.setProperties(this.editingModel);
    try {
      await this.args.currentWorkflowStepOption.save();
      this.isSaving = false;
      this.toasts.success({
        data: {
          message: i18n("admin.discourse_workflow.workflows.steps.saved"),
        },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.discourse-workflow-workflows.steps.edit",
        this.args.currentWorkflowStepOption.workflow_step_id
      );
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
      message: i18n("admin.discourse_workflow.workflows.steps.confirm_delete"),
      didConfirm: () => {
        return this.args.currentWorkflowStepOption.destroyRecord().then(() => {
          this.toasts.success({
            data: {
              message: i18n("admin.discourse_workflow.workflows.steps.deleted"),
            },
            duration: 2000,
          });
          this.router.transitionTo(
            "adminPlugins.show.discourse-workflow-workflows.edit",
            this.args.currentWorkflowStepOption.workflow_id
          );
        });
      },
    });
  }

  get availableSteps() {
    const steps = this.args.workflowSteps || [];
    const filteredSteps = steps
      .map(({ id, name, description }) => ({ id, name, description }))
      .filter((step) => step.id !== this.args.workflowStep.id);
    return filteredSteps;
  }

  <template>
    <WorkflowBackButton
      @route="adminPlugins.show.discourse-workflow-workflows.steps.edit"
      @model={{@currentWorkflowStepOption.workflow_step_id}}
    />
    {{#if @currentWorkflowStepOption.id}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.option.editing.title"
          position=@currentWorkflowStepOption.position
        }}</h2>
    {{else}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.option.new.title"
        }}</h2>
    {{/if}}
    <form
      class="form-horizontal workflow-step-editor"
      {{didUpdate this.updateModel @currentWorkflowStepOption.id}}
      {{didInsert this.updateModel @currentWorkflowStepOption.id}}
    >
      <div class="control-group">
        <label>{{I18n.t "admin.discourse_workflow.workflows.name"}}</label>
        <DropdownSelectBox
          @value={{this.editingModel.workflow_option_id}}
          @content={{@workflowOptions}}
          @onChange={{fn (mut this.editingModel.workflow_option_id)}}
          @options={{hash
            disabled=this.editingModel.system
            none="admin.discourse_workflow.workflows.steps.options.select_an_option"
          }}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.steps.options.target_step"
          }}</label>
        <DropdownSelectBox
          @value={{this.editingModel.target_step_id}}
          @content={{this.availableSteps}}
          @onChange={{fn (mut this.editingModel.target_step_id)}}
          @options={{hash
            disabled=this.editingModel.system
            none="admin.discourse_workflow.workflows.steps.options.no_target_step"
          }}
        />
      </div>
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
